require 'dentaku/token_scanner'

describe Dentaku::TokenScanner do
  let(:whitespace) { described_class.new(:whitespace, '\s') }
  let(:numeric)    { described_class.new(:numeric,    '(\d+(\.\d+)?|\.\d+)',
    ->(raw) { raw =~ /\./ ? BigDecimal.new(raw) : raw.to_i })
  }
  let(:custom)     { described_class.new(:identifier, '#\w+\b',
    ->(raw) { raw.gsub('#', '').to_sym })
  }

  after { described_class.register_default_scanners }

  it 'returns a token for a matching string' do
    token = whitespace.scan(' ').first
    expect(token.category).to eq(:whitespace)
    expect(token.value).to eq(' ')
  end

  it 'returns falsy for a non-matching string' do
    expect(whitespace.scan('A')).not_to be
  end

  it 'performs raw value conversion' do
    token = numeric.scan('5').first
    expect(token.category).to eq(:numeric)
    expect(token.value).to eq(5)
  end

  it 'returns a list of all configured scanners' do
    expect(described_class.scanners.length).to eq 14
  end

  it 'allows customizing available scanners' do
    described_class.scanners = [:whitespace, :numeric]
    expect(described_class.scanners.length).to eq 2
  end

  it 'ignores invalid scanners' do
    described_class.scanners = [:whitespace, :numeric, :fake]
    expect(described_class.scanners.length).to eq 2
  end

  it 'uses a custom scanner' do
    described_class.scanners = [:whitespace, :numeric]
    described_class.register_scanner(:custom, custom)
    expect(described_class.scanners.length).to eq 3

    token = custom.scan('#apple + #pear').first
    expect(token.category).to eq(:identifier)
    expect(token.value).to eq(:apple)
  end
end
