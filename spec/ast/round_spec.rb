require 'spec_helper'
require 'dentaku/ast/functions/round'
require 'dentaku'

describe 'Dentaku::AST::Function::Round' do
  it 'returns the rounded down value' do
    result = Dentaku('ROUND(1.8)')
    expect(result).to eq 2
  end

  it 'returns the rounded down value to the given precision' do
    result = Dentaku('ROUND(x, y)', x: 1.8453, y: 3)
    expect(result).to eq 1.845
  end

  it 'returns the rounded down value to the given precision, also with strings' do
    result = Dentaku('ROUND(x, y)', x: '1.8453', y: '3')
    expect(result).to eq 1.845
  end

  it 'returns the rounded down value to the given precision, also with nil' do
    result = Dentaku('ROUND(x, y)', x: '1.8453', y: nil)
    expect(result).to eq 2
  end
end
