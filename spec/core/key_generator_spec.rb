require "rspec"
require "core/key_generator"

RSpec.describe Core::KeyGenerator do
  it 'generates a valid key' do
    result = described_class.call

    expect(result).to be_a(Hash)
    expect(result[:address]).to match(/^tb1[a-z0-9]{39,59}$/)
    expect(result[:public_key]).to match(/^0[2-3][0-9a-f]{64}$/)
  end

  it 'raises an error for invalid input' do
    expect { described_class.call(nil) }.to raise_error(ArgumentError)
  end
end
