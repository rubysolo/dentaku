require 'spec_helper'
require 'dentaku/ast/comparators'

require 'dentaku/token'

describe Dentaku::AST::Comparator do
  let(:one) { Dentaku::AST::Numeric.new Dentaku::Token.new(:numeric, 1) }
  let(:one_str) { Dentaku::AST::String.new Dentaku::Token.new(:string, '1') }
  let(:two) { Dentaku::AST::Numeric.new Dentaku::Token.new(:numeric, 2) }
  let(:two_str) { Dentaku::AST::String.new Dentaku::Token.new(:string, '2') }
  let(:x) { Dentaku::AST::Identifier.new Dentaku::Token.new(:identifier, 'x') }
  let(:y) { Dentaku::AST::Identifier.new Dentaku::Token.new(:identifier, 'y') }
  let(:nilly) do
    Dentaku::AST::Identifier.new Dentaku::Token.new(:identifier, 'nilly')
  end
  let(:ctx) { { 'x' => 'hello', 'y' => 'world', 'nilly' => nil } }

  it 'performs comparison with numeric operands' do
    expect(less_than(one, two).value(ctx)).to be_truthy
    expect(less_than(two, one).value(ctx)).to be_falsey
    expect(greater_than(two, one).value(ctx)).to be_truthy
    expect(not_equal(x, y).value(ctx)).to be_truthy
    expect(equal(x, y).value(ctx)).to be_falsey
  end

  it 'performs conversion from string to numeric operands' do
    expect(less_than(one, two_str).value(ctx)).to be_truthy
    expect(less_than(one_str, two_str).value(ctx)).to be_truthy
    expect(less_than(one_str, two).value(ctx)).to be_truthy
  end

  it 'raises a dentaku argument error when incorrect arguments are passed in' do
    expect { less_than(one, nilly).value(ctx) }.to raise_error Dentaku::ArgumentError
    expect { less_than_or_equal(one, nilly).value(ctx) }.to raise_error Dentaku::ArgumentError
    expect { greater_than(one, nilly).value(ctx) }.to raise_error Dentaku::ArgumentError
    expect { greater_than_or_equal(one, nilly).value(ctx) }.to raise_error Dentaku::ArgumentError
    expect { greater_than_or_equal(one, x).value(ctx) }.to raise_error Dentaku::ArgumentError
    expect { not_equal(one, nilly).value(ctx) }.to_not raise_error
    expect { equal(one, nilly).value(ctx) }.to_not raise_error
  end

  it 'raises a dentaku argument error when nil is passed in as first argument' do
    expect { less_than(nilly, one).value(ctx) }.to raise_error Dentaku::ArgumentError
    expect { less_than_or_equal(nilly, one).value(ctx) }.to raise_error Dentaku::ArgumentError
    expect { greater_than(nilly, one).value(ctx) }.to raise_error Dentaku::ArgumentError
    expect { greater_than_or_equal(nilly, one).value(ctx) }.to raise_error Dentaku::ArgumentError
    expect { not_equal(nilly, one).value(ctx) }.to_not raise_error
    expect { equal(nilly, one).value(ctx) }.to_not raise_error
  end

  it 'returns correct operator symbols' do
    expect(less_than(one, two).operator).to eq(:<)
    expect(less_than_or_equal(one, two).operator).to eq(:<=)
    expect(greater_than(one, two).operator).to eq(:>)
    expect(greater_than_or_equal(one, two).operator).to eq(:>=)
    expect(not_equal(x, y).operator).to eq(:!=)
    expect(equal(x, y).operator).to eq(:==)
    expect { Dentaku::AST::Comparator.new(one, two).operator }
      .to raise_error(NotImplementedError)
  end

  private

  def less_than(left, right)
    Dentaku::AST::LessThan.new(left, right)
  end

  def less_than_or_equal(left, right)
    Dentaku::AST::LessThanOrEqual.new(left, right)
  end

  def greater_than(left, right)
    Dentaku::AST::GreaterThan.new(left, right)
  end

  def greater_than_or_equal(left, right)
    Dentaku::AST::GreaterThanOrEqual.new(left, right)
  end

  def not_equal(left, right)
    Dentaku::AST::NotEqual.new(left, right)
  end

  def equal(left, right)
    Dentaku::AST::Equal.new(left, right)
  end
end
