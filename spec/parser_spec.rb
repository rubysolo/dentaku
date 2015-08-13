require 'spec_helper'
require 'dentaku/parser'

describe Dentaku::Parser do
  it 'is constructed from a token' do
    token = Dentaku::Token.new(:numeric, 5)
    node  = described_class.new([token]).parse
    expect(node.value).to eq 5
  end

  it 'performs simple addition' do
    five = Dentaku::Token.new(:numeric, 5)
    plus = Dentaku::Token.new(:operator, :add)
    four = Dentaku::Token.new(:numeric, 4)

    node  = described_class.new([five, plus, four]).parse
    expect(node.value).to eq 9
  end

  it 'compares two numbers' do
    five = Dentaku::Token.new(:numeric, 5)
    lt   = Dentaku::Token.new(:comparator, :lt)
    four = Dentaku::Token.new(:numeric, 4)

    node  = described_class.new([five, lt, four]).parse
    expect(node.value).to eq false
  end

  it 'performs multiple operations in one stream' do
    five  = Dentaku::Token.new(:numeric, 5)
    plus  = Dentaku::Token.new(:operator, :add)
    four  = Dentaku::Token.new(:numeric, 4)
    times = Dentaku::Token.new(:operator, :multiply)
    three = Dentaku::Token.new(:numeric, 3)

    node  = described_class.new([five, plus, four, times, three]).parse
    expect(node.value).to eq 17
  end

  it 'respects order of operations' do
    five  = Dentaku::Token.new(:numeric, 5)
    times = Dentaku::Token.new(:operator, :multiply)
    four  = Dentaku::Token.new(:numeric, 4)
    plus  = Dentaku::Token.new(:operator, :add)
    three = Dentaku::Token.new(:numeric, 3)

    node  = described_class.new([five, times, four, plus, three]).parse
    expect(node.value).to eq 23
  end

  it 'respects grouping by parenthesis' do
    lpar  = Dentaku::Token.new(:grouping, :open)
    five  = Dentaku::Token.new(:numeric, 5)
    plus  = Dentaku::Token.new(:operator, :add)
    four  = Dentaku::Token.new(:numeric, 4)
    rpar  = Dentaku::Token.new(:grouping, :close)
    times = Dentaku::Token.new(:operator, :multiply)
    three = Dentaku::Token.new(:numeric, 3)

    node  = described_class.new([lpar, five, plus, four, rpar, times, three]).parse
    expect(node.value).to eq 27
  end

  it 'evaluates functions' do
    fn    = Dentaku::Token.new(:function, :if)
    fopen = Dentaku::Token.new(:grouping, :fopen)
    five  = Dentaku::Token.new(:numeric, 5)
    lt    = Dentaku::Token.new(:comparator, :lt)
    four  = Dentaku::Token.new(:numeric, 4)
    comma = Dentaku::Token.new(:grouping, :comma)
    three = Dentaku::Token.new(:numeric, 3)
    two   = Dentaku::Token.new(:numeric, 2)
    rpar  = Dentaku::Token.new(:grouping, :close)

    node  = described_class.new([fn, fopen, five, lt, four, comma, three, comma, two, rpar]).parse
    expect(node.value).to eq 2
  end

  it 'represents formulas with variables' do
    five  = Dentaku::Token.new(:numeric, 5)
    times = Dentaku::Token.new(:operator, :multiply)
    x     = Dentaku::Token.new(:identifier, :x)

    node  = described_class.new([five, times, x]).parse
    expect { node.value }.to raise_error
    expect(node.value(x: 3)).to eq 15
  end

  it 'evaluates boolean expressions' do
    d_true  = Dentaku::Token.new(:logical, true)
    d_and   = Dentaku::Token.new(:combinator, :and)
    d_false = Dentaku::Token.new(:logical, false)

    node  = described_class.new([d_true, d_and, d_false]).parse
    expect(node.value).to eq false
  end
end
