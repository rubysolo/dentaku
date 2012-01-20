require 'dentaku/token'

describe Dentaku::Token do
  it 'should have a category and a value' do
    token = Dentaku::Token.new(:numeric, 5)
    token.category.should eq(:numeric)
    token.value.should eq(5)
    token.is?(:numeric).should be_true
  end
end
