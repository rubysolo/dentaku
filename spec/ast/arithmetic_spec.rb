require 'spec_helper'
require 'dentaku/ast/arithmetic'
require 'dentaku'

describe Dentaku::AST::Arithmetic do
  let(:one)  { Dentaku::AST::Numeric.new(Dentaku::Token.new(:numeric, 1)) }
  let(:two)  { Dentaku::AST::Numeric.new(Dentaku::Token.new(:numeric, 2)) }
  let(:x)    { Dentaku::AST::Identifier.new(Dentaku::Token.new(:identifier, 'x')) }
  let(:y)    { Dentaku::AST::Identifier.new(Dentaku::Token.new(:identifier, 'y')) }
  let(:ctx)  { {'x' => 1, 'y' => 2} }
  let(:date) { Dentaku::AST::DateTime.new(Dentaku::Token.new(:datetime, DateTime.new(2020, 4, 16))) }

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

  it 'correctly parses string operands to numeric values' do
    expect(add(x, one, 'x' => '1')).to eq(2)
    expect(add(x, one, 'x' => '1.1')).to eq(2.1)
    expect(add(x, one, 'x' => '.1')).to eq(1.1)
    expect { add(x, one, 'x' => 'invalid') }.to raise_error(Dentaku::ArgumentError)
    expect { add(x, one, 'x' => '') }.to raise_error(Dentaku::ArgumentError)

    int_one = Dentaku::AST::Numeric.new(Dentaku::Token.new(:numeric, "1"))
    int_neg_one = Dentaku::AST::Numeric.new(Dentaku::Token.new(:numeric, "-1"))
    decimal_one = Dentaku::AST::Numeric.new(Dentaku::Token.new(:numeric, "1.0"))
    decimal_neg_one = Dentaku::AST::Numeric.new(Dentaku::Token.new(:numeric, "-1.0"))

    [int_one, int_neg_one].permutation(2).each do |(left, right)|
      expect(add(left, right).class).to eq(Integer)
    end

    [decimal_one, decimal_neg_one].each do |left|
      [int_one, int_neg_one, decimal_one, decimal_neg_one].each do |right|
        expect(add(left, right).class).to eq(BigDecimal)
      end
    end
  end

  it 'performs arithmetic on arrays' do
    expect(add(x, y, 'x' => [1], 'y' => [2])).to eq([1, 2])
    expect(sub(x, y, 'x' => [1], 'y' => [2])).to eq([1])
  end

  it 'performs date arithmetic' do
    expect(add(date, one)).to eq(DateTime.new(2020, 4, 17))
    expect(sub(date, one)).to eq(DateTime.new(2020, 4, 15))
  end

  it 'performs arithmetic on object which implements arithmetic' do
    CanHazMath = Struct.new(:value) do
      extend Forwardable

      def_delegators :value, :zero?

      def coerce(other)
        case other
        when Numeric
          [other, value]
        else
          super
        end
      end

      [:+, :-, :/, :*].each do |operand|
        define_method(operand) do |other|
          case other
          when CanHazMath
            value.public_send(operand, other.value)
          when Numeric
            value.public_send(operand, other)
          end
        end
      end
    end

    op_one = CanHazMath.new(1)
    op_two = CanHazMath.new(2)

    [op_two, two].each do |left|
      [op_one, one].each do |right|
        expect(add(x, y, 'x' => left, 'y' => right)).to eq(3)
        expect(sub(x, y, 'x' => left, 'y' => right)).to eq(1)
        expect(mul(x, y, 'x' => left, 'y' => right)).to eq(2)
        expect(div(x, y, 'x' => left, 'y' => right)).to eq(2)
      end
    end
  end

  it 'raises ArgumentError if given individually valid but incompatible arguments' do
    expect { add(one, date) }.to raise_error(Dentaku::ArgumentError)
    expect { add(x, one, 'x' => [1]) }.to raise_error(Dentaku::ArgumentError)
  end

  private

  def add(left, right, context = ctx)
    Dentaku::AST::Addition.new(left, right).value(context)
  end

  def sub(left, right, context = ctx)
    Dentaku::AST::Subtraction.new(left, right).value(context)
  end

  def mul(left, right, context = ctx)
    Dentaku::AST::Multiplication.new(left, right).value(context)
  end

  def div(left, right, context = ctx)
    Dentaku::AST::Division.new(left, right).value(context)
  end

  def neg(node, context = ctx)
    Dentaku::AST::Negation.new(node).value(context)
  end
end
