require 'dentaku/token_scanner'

describe Dentaku::TokenScanner do
  let(:whitespace) { described_class.new(:whitespace, '\s') }
  let(:numeric)    { described_class.new(:numeric,    '(\d+(\.\d+)?|\.\d+)', lambda{|raw| raw =~ /\./ ? raw.to_f : raw.to_i }) }

  it 'should return a token for a matching string' do
    token = whitespace.scan(' ')
    token.category.should eq(:whitespace)
    token.value.should eq(' ')
  end

  it 'should return falsy for a non-matching string' do
    whitespace.scan('A').should_not be
  end

  it 'should perform raw value conversion' do
    token = numeric.scan('5')
    token.category.should eq(:numeric)
    token.value.should eq(5)
  end

  it 'should return a list of all configured scanners' do
    described_class.scanners.length.should eq 10
  end
end

