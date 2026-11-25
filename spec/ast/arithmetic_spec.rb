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

  it 'does not try to parse nested string as date' do
    a = ['2017-01-01', '2017-01-02']
    b = ['2017-01-01']

    expect(Dentaku('a - b', a: a, b: b)).to eq(['2017-01-02'])
  end

  it 'raises ArgumentError if given individually valid but incompatible arguments' do
    expect { add(one, date) }.to raise_error(Dentaku::ArgumentError)
    expect { add(x, one, 'x' => [1]) }.to raise_error(Dentaku::ArgumentError)
  end

  describe 'parse-time operand validation (#197)' do
    let(:calculator) do
      Dentaku::Calculator.new.tap do |c|
        c.add_function(:explode, :numeric, ->(*) { raise "function executed at parse time" })
        c.add_function(:explode_flag, :logical, ->(*) { raise "function executed at parse time" })
      end
    end

    it 'does not execute functions when an IF is an arithmetic operand' do
      expect {
        calculator.ast("IF(explode(1) = 1, 1, 2) + category")
      }.not_to raise_error
    end

    it 'does not execute functions when an IF is negated' do
      expect {
        calculator.ast("-IF(explode(1) = 1, 1, 2)")
      }.not_to raise_error
    end

    it 'does not execute functions when an IF is a combinator operand' do
      expect {
        calculator.ast("IF(explode_flag(), true, false) AND x")
      }.not_to raise_error
    end

    it 'does not execute functions when a CASE is an arithmetic operand' do
      expect {
        calculator.ast("(CASE explode(1) WHEN 1 THEN 1 ELSE 2 END) + category")
      }.not_to raise_error
    end

    it 'reports identifiers across both branches without evaluating' do
      expect(calculator.identifiers("IF(explode(1) = 1, 1, 2) + category")).to eq(["category"])
    end

    it 'still validates operand types' do
      expect { Dentaku::Calculator.new.ast("'abc' + 1") }.to raise_error(Dentaku::ParseError)
    end

    it 'leaves evaluation and short-circuiting unchanged' do
      plain = Dentaku::Calculator.new

      expect(plain.evaluate!("IF(a = 1, 10, 20) + 5", a: 1)).to eq(15)
      expect(plain.evaluate!("IF(a = 1, 10, 20) + 5", a: 2)).to eq(25)
      expect(plain.evaluate!("-IF(a = 1, 10, 20)", a: 1)).to eq(-10)
      expect(plain.dependencies("IF(a, b, c)", a: true)).to eq(["b"])
    end
  end

  describe 'operations that reject well-typed operands (#332)' do
    let(:oversized) { "999999999999999 ^ 99999999999999" }

    it 'wraps the raw Ruby error so it is a Dentaku::Error' do
      # Ruby 3.4+ raises ArgumentError('exponent is too large') and we pass its
      # message through; older Rubies only warn and return Infinity, which the
      # non-finite result guard turns into the equivalent Dentaku error.
      expect {
        Dentaku::Calculator.new.evaluate!(oversized)
      }.to raise_error(Dentaku::ArgumentError, /more than \d+ digits|exponent is too large|is not a finite number/)
    end

    it 'is rescuable as Dentaku::Error' do
      error = begin
        Dentaku::Calculator.new.evaluate!(oversized)
        nil
      rescue Dentaku::Error => e
        e
      end

      expect(error).to be_a(Dentaku::ArgumentError)
    end

    it 'returns nil from the non-bang evaluate rather than raising' do
      expect(Dentaku::Calculator.new.evaluate(oversized)).to be_nil
      expect(Dentaku::Calculator.new.evaluate("2 ^ 99999999999")).to be_nil
    end

    it 'yields to the block form' do
      handled = nil
      Dentaku::Calculator.new.evaluate(oversized) { |_expr, ex| handled = ex }

      expect(handled).to be_a(Dentaku::ArgumentError)
    end

    it 'still evaluates exponentiation that fits' do
      expect(Dentaku::Calculator.new.evaluate!("2 ^ 10")).to eq(1024)
    end

    it 'still evaluates large results that BigDecimal can represent' do
      expect(Dentaku::Calculator.new.evaluate!("1e308 * 10")).to eq(BigDecimal("1e309"))
    end

    it 'leaves arithmetic alone when an operand is already infinite' do
      calculator = Dentaku::Calculator.new

      expect(calculator.evaluate!("a + 1", a: Float::INFINITY)).to be_infinite
      expect(calculator.evaluate!("a * 2", a: Float::INFINITY)).to be_infinite
    end

    it 'does not swallow Dentaku errors raised by the operation itself' do
      expect {
        Dentaku::Calculator.new.evaluate!("1 / 0")
      }.to raise_error(Dentaku::ZeroDivisionError)
    end
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
