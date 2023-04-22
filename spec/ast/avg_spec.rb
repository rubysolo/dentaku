require 'spec_helper'
require 'dentaku/ast/functions/avg'
require 'dentaku'

describe 'Dentaku::AST::Function::Avg' do
  it 'returns the average of an array of Numeric values as BigDecimal' do
    result = Dentaku('AVG(1, 2)')
    expect(result).to eq(1.5)
  end

  it 'returns the average of an array of Numeric values' do
    result = Dentaku('AVG(1, x, 1.8)', x: 2.3)
    expect(result).to eq(1.7)
  end

  it 'returns the average of a single entry array of a Numeric value' do
    result = Dentaku('AVG(x)', x: 2.3)
    expect(result).to eq(2.3)
  end

  it 'returns the average even if a String is passed' do
    result = Dentaku('AVG(1, x, 1.8)', x: '2.3')
    expect(result).to eq(1.7)
  end

  it 'returns the average even if an array is passed' do
    result = Dentaku('AVG(1, x, 2.3)', x: [4, 5])
    expect(result).to eq(3.075)
  end

  context 'checking errors' do
    let(:calculator) { Dentaku::Calculator.new }

    it 'raises an error if no arguments are passed' do
      expect { calculator.evaluate!('AVG()') }.to raise_error(Dentaku::ArgumentError)
    end

    it 'raises an error if an empty array is passed' do
      expect { calculator.evaluate!('AVG(x)', x: []) }.to raise_error(Dentaku::ArgumentError)
    end
  end
end
