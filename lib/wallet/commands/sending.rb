require "json"
require "net/http"
require "uri"
require "bitcoin"
require "core/errors"

module Wallet
  module Commands
    MEMPOOL_URL = "https://mempool.space/signet/api"
    TRANSACTION_FEE = 1_000

    Bitcoin.chain_params = :signet

    class Sending
      attr_reader :wallet_name, :to_address, :amount_btc

      def initialize(wallet_name:, to:, amount:)
        @wallet_name = wallet_name
        @to_address = to
        @amount_btc = amount
        @wallet_path = File.join("wallets", "#{wallet_name}.json")
        @fee_sats = TRANSACTION_FEE
      end

      def call
        raise Core::Errors::WalletNotFound.new(@wallet_path), "Wallet file not found: #{@wallet_path}" unless File.exist?(@wallet_path)

        key, from_address = load_wallet_data

        utxos = UtxoFetcher.call(from_address)

        amount_sats = (@amount_btc * 100_000_000).to_i
        selected_utxos, total_input = UtxoSelector.call(utxos, amount_sats + @fee_sats)

        validate_funds!(total_input, amount_sats)
        # if total_input < amount_sats + @fee_sats
        #   raise Core::Errors::InsufficientFunds.new(
        #   needed: amount_sats + @fee_sats,
        #   available: total_input
        # )
        # end

        print_transaction_summary(amount_sats)

        unless user_confirmed?
          puts "\e[31m❌ Aborted by user\e[0m"
          return
        end

        tx = TransactionBuilder.call(
          utxos: selected_utxos,
          from: from_address,
          to: @to_address,
          amount: amount_sats,
          total: total_input,
          fee: @fee_sats,
          key: key
        )

        tx_hex = tx.to_payload.bth
        Broadcaster.call(tx_hex)

        [tx, tx_hex]
      end

      private

      def log(msg)
        puts "\e[33m #{msg}\e[0m"
      end

      def load_wallet_data
        data = JSON.parse(File.read(@wallet_path))

        key = Bitcoin::Key.from_wif(data["private_key"])
        address = data["address"]

        raise Core::Errors::InvalidWalletFormat, "Missing address or private key" unless key && address
        raise Core::Errors::KeyMismatch, @wallet_path unless key.to_p2wpkh == address

        [key, address]
      end

      def print_transaction_summary(amount_sats)
        puts "\n\e[36mTransaction summary:\e[0m"
        puts "  From: #{@wallet_name}"
        puts "  To:   #{@to_address}"
        puts "  Send: #{@amount_btc} BTC"
        puts "  Fee:  #{@fee_sats} sats"
        puts "  Total deducted: #{amount_sats + @fee_sats} sats"
      end

      def user_confirmed?
        print "\n  Proceed? (y/N): "
        STDIN.gets.strip.downcase == "y"
      end

      def validate_funds!(total_input, amount_sats)
        total_required = amount_sats + @fee_sats

        if total_input < total_required
          raise Core::Errors::InsufficientFunds.new(needed: total_required, available: total_input)
        end
      end
    end

    class UtxoFetcher
      def self.call(address)
        uri = URI("#{MEMPOOL_URL}/address/#{address}/utxo")
        response = Net::HTTP.get_response(uri)

        raise Core::Errors::ApiError, "Failed to fetch UTXOs: #{response.code} #{response.message}" unless response.is_a?(Net::HTTPSuccess)

        JSON.parse(response.body)
      end
    end

    class UtxoSelector
      def self.call(utxos, target_amount)
        selected = []
        total = 0

        utxos.each do |utxo|
          selected << utxo
          total += utxo["value"]
          break if total >= target_amount
        end

        [selected, total]
      end
    end

    class TransactionBuilder
      def self.call(utxos:, from:, to:, amount:, total:, fee:, key:)
        tx = Bitcoin::Tx.new

        utxos.each do |utxo|
          outpoint = Bitcoin::OutPoint.from_txid(utxo["txid"], utxo["vout"])
          txin = Bitcoin::TxIn.new(out_point: outpoint)
          tx.inputs << txin
        end

        tx.outputs << Bitcoin::TxOut.new(value: amount, script_pubkey: Bitcoin::Script.parse_from_addr(to))

        change = total - amount - fee
        if change > 0
          tx.outputs << Bitcoin::TxOut.new(value: change, script_pubkey: Bitcoin::Script.parse_from_addr(from))
        end

        script_pubkey = Bitcoin::Script.parse_from_addr(from)

        utxos.each_with_index do |utxo, i|
          sighash = tx.sighash_for_input(i, script_pubkey, sig_version: :witness_v0, amount: utxo["value"])
          signature = key.sign(sighash) + [Bitcoin::SIGHASH_TYPE[:all]].pack("C")

          witness = Bitcoin::ScriptWitness.new
          witness.stack << signature
          witness.stack << key.pubkey.htb
          tx.inputs[i].script_witness = witness
        end

        tx
      end
    end

    class Broadcaster
      def self.call(tx_hex)
        uri = URI("#{MEMPOOL_URL}/tx")
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true

        req = Net::HTTP::Post.new(uri.path, { 'Content-Type' => 'text/plain' })
        req.body = tx_hex
        res = http.request(req)

        if res.is_a?(Net::HTTPSuccess)
          res.body
        else
          puts "Failed to broadcast transaction: #{res.code} #{res.message}"
          raise Core::Errors::ApiError, "Failed to broadcast transaction: #{res.code} #{res.message}"
        end
      end
    end
  end
end
