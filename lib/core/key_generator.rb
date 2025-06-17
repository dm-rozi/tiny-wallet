require 'bitcoin'

module Core
  class KeyGenerator
    def self.call
      Bitcoin.chain_params = :signet

      key = Bitcoin::Key.generate

      {
        private_key: key.to_wif,
        address: key.to_p2wpkh,
        public_key: key.pubkey
      }
    end
  end
end
