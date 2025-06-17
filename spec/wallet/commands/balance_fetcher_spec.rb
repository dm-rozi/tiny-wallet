require "spec_helper"
require "wallet/commands/balance_fetcher"
require "vcr"

RSpec.describe Wallet::Commands::BalanceFetcher do
  let(:address) { "tb1q0gur99drlhcqtt4c6em662cmddw3ulqdq252dm" }

  describe "#call", :vcr do
    it "returns address, total sats and UTXOs from mempool" do
      fetcher = described_class.new(address: address)
      addr, sats, utxos = fetcher.call

      expect(addr).to eq(address)
      expect(sats).to be_a(Integer)
      expect(utxos).to be_a(Array)
      expect(utxos.size).to eq(2)
    end
  end

  context "when address is syntactically invalid" do
    let(:invalid_address) { "tb1q0gur99drlhcqtt4c6em662cmddw3ulqdq252dm55555555555555" }

    it "raises InvalidWalletFormat" do
      fetcher = described_class.new(address: invalid_address)

      expect {
        fetcher.call
      }.to raise_error(Core::Errors::InvalidWalletFormat)
    end
  end

  context "when neither address nor wallet_name is given" do
    it "raises InvalidWalletFormat" do
      expect {
        described_class.new.call
      }.to raise_error(Core::Errors::InvalidWalletFormat)
    end
  end

  context "when wallet file does not exist" do
    it "raises WalletNotFound" do
      fetcher = described_class.new(wallet_name: "missing_wallet")
      expect {
        fetcher.call
      }.to raise_error(Core::Errors::WalletNotFound)
    end
  end

  context "when wallet exists but address is missing" do
    before do
      FileUtils.mkdir_p("wallets")
      File.write("wallets/broken_wallet.json", { address: "" }.to_json)
    end

    after do
      FileUtils.rm_f("wallets/broken_wallet.json")
    end

    it "raises InvalidWalletData" do
      fetcher = described_class.new(wallet_name: "broken_wallet")
      expect {
        fetcher.call
      }.to raise_error(Core::Errors::InvalidWalletFormat)
    end
  end

  describe "with real address that has no UTXOs", :vcr do
    let(:no_bitcoin_address) { "tb1q0jvacce0kskzwnp4mj6esw8j95g0yyyvm3dc4h" }

    it "returns 0 sats and empty array" do
      fetcher = described_class.new(address: no_bitcoin_address)
      addr, sats, utxos = fetcher.call

      expect(addr).to eq(no_bitcoin_address)
      expect(sats).to eq(0)
      expect(utxos).to eq([])
    end
  end

  describe "when mempool API fails with errors", :vcr do

    it "it raises an API error" do
      bad_address = "tb1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqrererqqqqqqqqqqqqqqqqqqqq"
      fetcher = Wallet::Commands::BalanceFetcher.new(address: bad_address)

      expect {
        fetcher.send(:fetch_transactions, bad_address)
      }.to raise_error(Core::Errors::ApiError)
    end
  end
end
