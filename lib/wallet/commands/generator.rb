require "bitcoin"
require "json"
require "fileutils"
require "core/key_generator"
require "core/errors"

module Wallet
  module Commands
    class Generator
      def initialize(wallet_name)
        @wallet_name = wallet_name
        @wallet_path = File.join("wallets", "#{wallet_name}.json")
      end

      def call
        raise Core::Errors::WalletAlreadyExists.new(@wallet_path) if File.exist?(@wallet_path)

        wallet_data = Core::KeyGenerator.call
        create_wallet_directory(wallet_data)

        [@wallet_path, wallet_data]
      end

      private

      def create_wallet_directory(wallet_data)
        FileUtils.mkdir_p("wallets")
        File.write(@wallet_path, JSON.pretty_generate(wallet_data))
      rescue Errno::EACCES => e
        raise Core::Errors::PermissionDenied.new(@wallet_path), "Cannot write to #{@wallet_path}: #{e.message}"
      rescue StandardError => e
        raise Core::Errors::WalletError.new(@wallet_path), "Failed to create wallet: #{e.message}"
      end
    end
  end
end
