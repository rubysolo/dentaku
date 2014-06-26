require 'dentaku/token_scanner'

describe Dentaku::TokenScanner do
  let(:whitespace) { described_class.new(:whitespace, '\s') }
  let(:numeric)    { described_class.new(:numeric,    '(\d+(\.\d+)?|\.\d+)', lambda{|raw| raw =~ /\./ ? BigDecimal.new(raw) : raw.to_i }) }

  it 'returns a token for a matching string' do
    token = whitespace.scan(' ')
    expect(token.category).to eq(:whitespace)
    expect(token.value).to eq(' ')
  end

  it 'returns falsy for a non-matching string' do
    expect(whitespace.scan('A')).not_to be
  end

  it 'performs raw value conversion' do
    token = numeric.scan('5')
    expect(token.category).to eq(:numeric)
    expect(token.value).to eq(5)
  end

  it 'returns a list of all configured scanners' do
    expect(described_class.scanners.length).to eq 10
  end
end

