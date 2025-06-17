require "spec_helper"
require "wallet/commands/generator"
require "core/errors"
require "tmpdir"
require "fileutils"

RSpec.describe Wallet::Commands::Generator do
  let(:wallet_name) { "test_wallet" }
  let(:tmp_wallets_dir) { Dir.mktmpdir }
  let(:wallet_path) { File.join(tmp_wallets_dir, "#{wallet_name}.json") }

  before do
    allow(File).to receive(:join).and_call_original
    allow(File).to receive(:join).with("wallets", "#{wallet_name}.json").and_return(wallet_path)

    stub_const("Core::KeyGenerator", Class.new do
      def self.call
        { address: "test-address", public_key: "test-pubkey", private_key: "test-privkey" }
      end
    end)
  end

  after do
    FileUtils.remove_entry(tmp_wallets_dir) if File.exist?(tmp_wallets_dir)
  end

  describe "#call" do
    subject(:generator) { described_class.new(wallet_name) }

    context "when wallet does not exist" do
      it "creates a new wallet file and returns the path and data" do
        path, data = generator.call

        expect(File).to exist(wallet_path)
        json = JSON.parse(File.read(wallet_path), symbolize_names: true)
        expect(json[:address]).to eq("test-address")
        expect(data[:address]).to eq("test-address")
        expect(path).to eq(wallet_path)
      end
    end

    context "when wallet file already exists" do
      before do
        FileUtils.mkdir_p(tmp_wallets_dir)
        File.write(wallet_path, "{}")
      end

      it "raises WalletAlreadyExists error" do
        expect {
          generator.call
        }.to raise_error(Core::Errors::WalletAlreadyExists, /already exists/i)
      end
    end

    context "when file cannot be written due to permission error" do
      it "raises PermissionDenied error" do
        allow(File).to receive(:write).and_raise(Errno::EACCES)

        expect {
          generator.call
        }.to raise_error(Core::Errors::PermissionDenied, /Cannot write/)
      end
    end
  end
end
