require 'spec_helper'
require 'dentaku/ast/functions/mul'
require 'dentaku'

describe 'Dentaku::AST::Function::Mul' do
  it 'returns the product of an array of Numeric values' do
    result = Dentaku('MUL(1, x, 1.8)', x: 2.3)
    expect(result).to eq(4.14)
  end

  it 'returns the product of a single entry array of a Numeric value' do
    result = Dentaku('MUL(x)', x: 2.3)
    expect(result).to eq(2.3)
  end

  it 'coerces string inputs to numeric' do
    result = Dentaku('mul(1, x, 1.8)', x: '2.3')
    expect(result).to eq(4.14)
  end

  it 'returns the product even if an array is passed' do
    result = Dentaku('mul(1, x, 2.3)', x: [4, 5])
    expect(result).to eq(46)
  end

  it 'handles nested calls' do
    result = Dentaku('mul(1, x, mul(4, 5))', x: '2.3')
    expect(result).to eq(46)
  end

  context 'checking errors' do
    let(:calculator) { Dentaku::Calculator.new }

    it 'raises an error if no arguments are passed' do
      expect { calculator.evaluate!('MUL()') }.to raise_error(Dentaku::ArgumentError)
    end

    it 'does not raise an error if an empty array is passed' do
      result = calculator.evaluate!('MUL(x)', x: [])
      expect(result).to eq(1)
    end
  end
end
