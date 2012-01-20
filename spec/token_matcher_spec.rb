require 'dentaku/token_matcher'

describe Dentaku::TokenMatcher do
  it 'with single category should match token category' do
    matcher = described_class.new(:numeric)
    token   = Dentaku::Token.new(:numeric, 5)

    matcher.should == token
  end

  it 'with multiple categories should match any included token category' do
    matcher    = described_class.new([:comparator, :operator])
    numeric    = Dentaku::Token.new(:numeric, 5)
    comparator = Dentaku::Token.new(:comparator, :lt)
    operator   = Dentaku::Token.new(:operator, :add)

    matcher.should == comparator
    matcher.should == operator
    matcher.should_not == numeric
  end

  it 'with single category and value should match token category and value' do
    matcher     = described_class.new(:operator, :add)
    addition    = Dentaku::Token.new(:operator, :add)
    subtraction = Dentaku::Token.new(:operator, :subtract)

    matcher.should == addition
    matcher.should_not == subtraction
  end

  it 'with multiple values should match any included token value' do
    matcher = described_class.new(:operator, [:add, :subtract])
    add = Dentaku::Token.new(:operator, :add)
    sub = Dentaku::Token.new(:operator, :subtract)
    mul = Dentaku::Token.new(:operator, :multiply)
    div = Dentaku::Token.new(:operator, :divide)

    matcher.should == add
    matcher.should == sub
    matcher.should_not == mul
    matcher.should_not == div
  end

  it 'should be invertible' do
    matcher = described_class.new(:operator, [:add, :subtract]).invert
    add = Dentaku::Token.new(:operator, :add)
    mul = Dentaku::Token.new(:operator, :multiply)
    cmp = Dentaku::Token.new(:comparator, :lt)

    matcher.should_not == add
    matcher.should == mul
    matcher.should == cmp
  end
end

