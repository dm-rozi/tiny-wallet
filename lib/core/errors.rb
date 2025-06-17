module Core
  # Core module for wallet-related errors
  module Errors
    class WalletError < StandardError
      def initialize(path = nil)
        @path = path
      end
    end

    class WalletAlreadyExists < WalletError
      def message
        return "Wallet file already exists" unless @path

        "Wallet file already exists at: #{@path}"
      end
    end

    class InvalidWalletFormat < WalletError
      def message
        "Wallet file is invalid or corrupted"
      end
    end

    class MissingArgument < WalletError
      def initialize(arg)
        @arg = arg
      end

      def message
        "Missing required argument: #{@arg}"
      end
    end

    class KeyMismatch < WalletError
      def initialize(path)
        super("Private key does not match wallet address in file: #{path}")
      end
    end

    class InvalidAmount < WalletError
      def initialize(amount)
        @amount = amount
      end

      def message
        "Invalid amount: #{@amount.inspect}"
      end
    end

    class WalletNotFound < WalletError
      def message
        return "Wallet file not found" unless @path

        "Wallet file not found at: #{@path}"
      end
    end

    class PermissionDenied < WalletError
      def message
        return "Cannot write to wallet file" unless @path

        "Cannot write to wallet file at: #{@path}"
      end
    end

    class ApiError < WalletError
      def initialize(msg = "External API error")
        super(msg)
      end
    end

    class InsufficientFunds < WalletError
      def initialize(needed:, available:)
        super("Not enough funds. Needed: #{needed} sat, Available: #{available} sat")
      end
    end
  end
end
