require "json"
require "net/http"
require "uri"
require "core/errors"
require "core/wallet_validator"

module Wallet
  module Commands
    class BalanceFetcher
      def initialize(wallet_name: nil, address: nil)
        @wallet_name = wallet_name
        @address = address
      end

      def call
        raise Core::Errors::InvalidWalletFormat if @wallet_name.nil? && @address.nil?

        Core::Validator::AddressValidator.validate!(@address) if @address

        @address ||= resolve_address

        transactions_response = fetch_transactions(@address)
        utxos = JSON.parse(transactions_response.body)

        confirmed_total = utxos.sum { |u| u["value"] }

        [@address, confirmed_total, utxos]
      end

      private

      def resolve_address
        path = File.join("wallets", "#{@wallet_name}.json")
        raise Core::Errors::WalletNotFound.new(path) unless File.exist?(path)

        data = JSON.parse(File.read(path))
        addr = data["address"]
        raise Core::Errors::InvalidWalletFormat if addr.nil? || addr.empty?

        addr
      end

      def fetch_transactions(address)
        uri = URI("https://mempool.space/signet/api/address/#{address}/utxo")
        response = Net::HTTP.get_response(uri)

        unless response.is_a?(Net::HTTPSuccess)
          raise Core::Errors::ApiError.new("Failed to fetch transactions for address #{address}: #{response.message}")
        end

        response
      end
    end
  end
end
