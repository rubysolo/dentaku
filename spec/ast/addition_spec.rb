require 'spec_helper'
require 'dentaku/ast/arithmetic'

require 'dentaku/token'

describe Dentaku::AST::Addition do
  let(:five) { Dentaku::AST::Numeric.new Dentaku::Token.new(:numeric, 5) }
  let(:six)  { Dentaku::AST::Numeric.new Dentaku::Token.new(:numeric, 6) }

  let(:t)    { Dentaku::AST::Numeric.new Dentaku::Token.new(:logical, true) }

  it 'allows access to its sub-trees' do
    node = described_class.new(five, six)
    expect(node.left).to eq(five)
    expect(node.right).to eq(six)
  end

  it 'performs addition' do
    node = described_class.new(five, six)
    expect(node.value).to eq(11)
  end

  it 'requires operands that respond to +' do
    expect {
      described_class.new(five, t).value
    }.to raise_error(Dentaku::ArgumentError, /requires operands that respond to +/)

    expression = Dentaku::AST::Multiplication.new(five, five)
    group = Dentaku::AST::Grouping.new(expression)

    expect {
      described_class.new(group, five).value
    }.not_to raise_error
  end

  it 'allows operands that respond to addition' do
    # Sample struct that has a custom definition for addition
    Addable = Struct.new(:value) do
      def +(other)
        case other
        when Addable
          value + other.value
        when Numeric
          value + other
        end
      end
    end

    operand_five = Dentaku::AST::Numeric.new Dentaku::Token.new(:numeric, Addable.new(5))
    operand_six = Dentaku::AST::Numeric.new Dentaku::Token.new(:numeric, Addable.new(6))

    expect {
      described_class.new(operand_five, operand_six).value
    }.not_to raise_error

    expect {
      described_class.new(operand_five, six).value
    }.not_to raise_error
  end

  it 'does not try to parse nested string as date' do
    a = ['2017-01-01', '2017-01-02']
    b = ['2017-01-01']

    expect(Dentaku('a + b', a: a, b: b)).to eq(['2017-01-01', '2017-01-02', '2017-01-01'])
  end
end
