require "bitcoin"
require_relative "errors"

module Core
  module Validator
    class WifValidator
      def self.validate!(wif)
        Bitcoin::Key.from_wif(wif)
      rescue StandardError
        raise Core::Errors::InvalidWalletFormat, "Invalid WIF format"
      end
    end

    class AddressValidator
      def self.validate!(address)
        Bitcoin::Script.parse_from_addr(address)
      rescue StandardError
        raise Core::Errors::InvalidWalletFormat, "Invalid address format"
      end
    end

    class WalletDataValidator
      def self.validate!(data)
        WifValidator.validate!(data["private_key"])
        AddressValidator.validate!(data["address"])
        true
      end
    end
  end
end
