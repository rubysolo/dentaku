require 'spec_helper'
require 'dentaku/ast/arithmetic'

require 'dentaku/token'

describe Dentaku::AST::Arithmetic do
  let(:one) { Dentaku::AST::Numeric.new Dentaku::Token.new(:numeric, 1) }
  let(:two) { Dentaku::AST::Numeric.new Dentaku::Token.new(:numeric, 2) }
  let(:x)   { Dentaku::AST::Identifier.new Dentaku::Token.new(:identifier, 'x') }
  let(:y)   { Dentaku::AST::Identifier.new Dentaku::Token.new(:identifier, 'y') }
  let(:ctx) { {'x' => 1, 'y' => 2} }

  it 'performs an arithmetic operation with numeric operands' do
    expect(add(one, two)).to eq(3)
    expect(sub(one, two)).to eq(-1)
    expect(mul(one, two)).to eq(2)
    expect(div(one, two)).to eq(0.5)
    expect(neg(one)).to eq(-1)
  end

  it 'performs an arithmetic operation with one numeric operand and one string operand' do
    expect(add(one, x)).to eq(2)
    expect(sub(one, x)).to eq(0)
    expect(mul(one, x)).to eq(1)
    expect(div(one, x)).to eq(1)

    expect(add(y, two)).to eq(4)
    expect(sub(y, two)).to eq(0)
    expect(mul(y, two)).to eq(4)
    expect(div(y, two)).to eq(1)
  end

  it 'performs an arithmetic operation with string operands' do
    expect(add(x, y)).to eq(3)
    expect(sub(x, y)).to eq(-1)
    expect(mul(x, y)).to eq(2)
    expect(div(x, y)).to eq(0.5)
    expect(neg(x)).to eq(-1)
  end

  private

  def add(left, right)
    Dentaku::AST::Addition.new(left, right).value(ctx)
  end

  def sub(left, right)
    Dentaku::AST::Subtraction.new(left, right).value(ctx)
  end

  def mul(left, right)
    Dentaku::AST::Multiplication.new(left, right).value(ctx)
  end

  def div(left, right)
    Dentaku::AST::Division.new(left, right).value(ctx)
  end

  def neg(node)
    Dentaku::AST::Negation.new(node).value(ctx)
  end
end
