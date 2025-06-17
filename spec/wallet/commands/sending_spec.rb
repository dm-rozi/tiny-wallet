require "spec_helper"
require "wallet/commands/sending"

RSpec.describe Wallet::Commands::Sending do
  let(:wallet_name) { "test_wallet" }
  let(:wallet_path) { File.join("wallets", "#{wallet_name}.json") }
  let(:to_address) { "tb1qmq7j7up7qdunum3u4ty2s90af7ujd8aslv5nv3" }
  let(:amount_btc) { 0.00043 }

  before do
    FileUtils.mkdir_p("wallets")

    File.write(wallet_path, {
      "private_key": "cUTxrwur4J7VEhNNpHyw9R7HPCpKtwcQX1MNSVAgsBeEhafHtCY3",
      "address": "tb1qefu0dkj6uups6n4w9fdxzu2xc0z85ug4kazhec",
      "public_key": "03fcb829ff033b9dfda302aae7abd8aaf602c67e54d4d0837f46f7e0da37e07c52"
    }.to_json)
  end

  after do
    FileUtils.rm_f(wallet_path)
  end

  describe "#call", :vcr do
    it "sends transaction and returns tx + hex" do
      VCR.current_cassette.name.tap { |name| puts "VCR Cassette: #{name}" }

      sender = described_class.new(wallet_name: wallet_name, to: to_address, amount: amount_btc)

      allow(sender).to receive(:user_confirmed?).and_return(true)
      allow(sender).to receive(:print_transaction_summary)

      tx, tx_hex = sender.call

      expect(tx).to be_a(Bitcoin::Tx)
      expect(tx_hex).to be_a(String)
      expect(tx_hex).to match(/\A[0-9a-f]+\z/i)
    end
  end

  describe "#call insufficient funds", :vcr do
    it "raises InsufficientFunds error" do
      sender = described_class.new(wallet_name: wallet_name, to: to_address, amount: 20) # слишком много

      allow(sender).to receive(:user_confirmed?).and_return(true)
      allow(sender).to receive(:print_transaction_summary)

      expect {
        sender.call
      }.to raise_error(Core::Errors::InsufficientFunds)
    end
  end

  describe "#call with key mismatch" do
    before do
      File.write(wallet_path, {
        private_key: "cT96vocmHTNasCvwL4GtFhQrPABEHQqADiVcHtTXU418fyZbiqhu", # другой ключ
        address: "tb1qefu0dkj6uups6n4w9fdxzu2xc0z85ug4kazhec"
      }.to_json)
    end

    it "raises KeyMismatch error" do
      sender = described_class.new(wallet_name: wallet_name, to: to_address, amount: amount_btc)

      expect {
        sender.call
      }.to raise_error(Core::Errors::KeyMismatch)
    end
  end

  describe "#call without wallet file" do
    it "raises WalletNotFound error" do
      FileUtils.rm_f(wallet_path)
      sender = described_class.new(wallet_name: wallet_name, to: to_address, amount: amount_btc)

      expect {
        sender.call
      }.to raise_error(Core::Errors::WalletNotFound)
    end
  end
end
