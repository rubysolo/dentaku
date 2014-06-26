require 'dentaku/token'

describe Dentaku::Token do
  it 'has a category and a value' do
    token = Dentaku::Token.new(:numeric, 5)
    expect(token.category).to eq(:numeric)
    expect(token.value).to eq(5)
    expect(token.is?(:numeric)).to be_truthy
  end
end
