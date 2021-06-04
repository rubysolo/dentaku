require 'spec_helper'
require 'dentaku/ast/functions/sum'
require 'dentaku'

describe 'Dentaku::AST::Function::Sum' do
  it 'returns the sum of an array of Numeric values' do
    result = Dentaku('SUM(1, x, 1.8)', x: 2.3)
    expect(result).to eq(5.1)
  end

  it 'returns the sum of a single entry array of a Numeric value' do
    result = Dentaku('SUM(x)', x: 2.3)
    expect(result).to eq(2.3)
  end

  it 'returns the sum even if a String is passed' do
    result = Dentaku('SUM(1, x, 1.8)', x: '2.3')
    expect(result).to eq(5.1)
  end

  it 'returns the sum even if an array is passed' do
    result = Dentaku('SUM(1, x, 2.3)', x: [4, 5])
    expect(result).to eq(12.3)
  end

  it 'returns the sum of nested sums' do
    result = Dentaku('SUM(1, x, SUM(4, 5))', x: '2.3')
    expect(result).to eq(12.3)
  end

  context 'checking errors' do
    let(:calculator) { Dentaku::Calculator.new }

    it 'raises an error if no arguments are passed' do
      expect { calculator.evaluate!('SUM()') }.to raise_error(Dentaku::ArgumentError)
    end

    it 'does not raise an error if an empty array is passed' do
      result = calculator.evaluate!('SUM(x)', x: [])
      expect(result).to eq(0)
    end
  end
end
