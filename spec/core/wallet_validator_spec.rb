require "spec_helper"
require "core/wallet_validator"


RSpec.describe Core::Validator::WifValidator do
  it "validates a correct WIF" do
    expect {
      Core::Validator::WifValidator.validate!("cNuURyTV8LSLAEqkG9Czg5aBdKqxxwVAc9o41PmzYZeBxBryVy7v")
    }.not_to raise_error
  end

  it "raises on invalid WIF" do
    expect {
      Core::Validator::WifValidator.validate!("invalid-wif")
    }.to raise_error(Core::Errors::InvalidWalletFormat)
  end
end

RSpec.describe Core::Validator::AddressValidator do
  it "validates a correct address" do
    expect {
      Core::Validator::AddressValidator.validate!("tb1qmq7j7up7qdunum3u4ty2s90af7ujd8aslv5nv3")
    }.not_to raise_error
  end

  it "raises on invalid address" do
    expect {
      Core::Validator::AddressValidator.validate!("invalid-address")
    }.to raise_error(Core::Errors::InvalidWalletFormat)
  end
end

RSpec.describe Core::Validator::WalletDataValidator do
  it "validates correct wallet data" do
    expect {
      Core::Validator::WalletDataValidator.validate!({
        "private_key" => "cNuURyTV8LSLAEqkG9Czg5aBdKqxxwVAc9o41PmzYZeBxBryVy7v",
        "address" => "tb1qmq7j7up7qdunum3u4ty2s90af7ujd8aslv5nv3"
      })
    }.not_to raise_error
  end

  it "raises on invalid wallet data" do
    expect {
      Core::Validator::WalletDataValidator.validate!({
        "private_key" => "invalid-wif",
        "address" => "invalid-address"
      })
    }.to raise_error(Core::Errors::InvalidWalletFormat)
  end
end
