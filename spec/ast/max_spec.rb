require 'spec_helper'
require 'dentaku/ast/functions/max'
require 'dentaku'

describe 'Dentaku::AST::Function::Max' do
  it 'returns the largest numeric value in an array of Numeric values' do
    result = Dentaku('MAX(1, x, 1.8)', x: 2.3)
    expect(result).to eq(2.3)
  end

  it 'returns the largest value even if a String is passed' do
    result = Dentaku('MAX(1, x, 1.8)', x: '2.3')
    expect(result).to eq(2.3)
  end

  it 'returns the largest value even if an Array is passed' do
    result = Dentaku('MAX(1, x, 1.8)', x: [1.5, 2.3, 1.7])
    expect(result).to eq(2.3)
  end

  it 'returns the largest value if only an Array is passed' do
    result = Dentaku('MAX(x)', x: [1.5, 2.3, 1.7])
    expect(result).to eq(2.3)
  end

  context 'checking errors' do
    let(:calculator) { Dentaku::Calculator.new }

    it 'does not raise an error if an empty array is passed' do
      expect(calculator.evaluate!('MAX(x)', x: [])).to eq(nil)
    end
  end
end
