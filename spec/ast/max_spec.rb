require 'spec_helper'
require 'dentaku/ast/functions/max'
require 'dentaku'

describe 'Dentaku::AST::Function::Max' do
  it 'returns the largest numeric value in an array of Numeric values' do
    result = Dentaku('MAX(1, x, 1.8)', x: 2.3)
    expect(result).to eq 2.3
  end

  it 'returns the largest value even if a String is passed' do
    result = Dentaku('MAX(1, x, 1.8)', x: '2.3')
    expect(result).to eq 2.3
  end

  it 'returns the largest value even if an Array is passed' do
    result = Dentaku('MAX(1, x, 1.8)', x: [1.5, 2.3, 1.7])
    expect(result).to eq 2.3
  end
end
