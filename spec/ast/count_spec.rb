require 'spec_helper'
require 'dentaku/ast/functions/count'
require 'dentaku'

describe 'Dentaku::AST::Count' do
  it 'returns the length of an array' do
    result = Dentaku('COUNT(1, x, 1.8)', x: 2.3)
    expect(result).to eq(3)
  end

  it 'returns the length of a single number object' do
    result = Dentaku('COUNT(x)', x: 2.3)
    expect(result).to eq(1)
  end

  it 'returns the length if a single String is passed' do
    result = Dentaku('COUNT(x)', x: 'dentaku')
    expect(result).to eq(7)
  end

  it 'returns the length if an array is passed' do
    result = Dentaku('COUNT(x)', x: [4, 5])
    expect(result).to eq(2)
  end

  it 'returns the length if an array with one element is passed' do
    result = Dentaku('COUNT(x)', x: [4])
    expect(result).to eq(1)
  end

  it 'returns the length if an array even if it has nested array' do
    result = Dentaku('COUNT(1, x, 3)', x: [4, 5])
    expect(result).to eq(3)
  end

  it 'returns the length if an array is passed' do
    result = Dentaku('COUNT()')
    expect(result).to eq(0)
  end
end
