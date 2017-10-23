require 'dentaku/token'

describe Dentaku::Token do
  it 'has a category and a value' do
    token = Dentaku::Token.new(:numeric, 5)
    expect(token.category).to eq(:numeric)
    expect(token.value).to eq(5)
    expect(token.is?(:numeric)).to be_truthy
  end

  it 'compares category and value to determine equality' do
    t1 = Dentaku::Token.new(:numeric, 5)
    t2 = Dentaku::Token.new(:numeric, 5)
    expect(t1 == t2).to be_truthy
  end
end
