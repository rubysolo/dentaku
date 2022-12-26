require 'spec_helper'
require 'dentaku/ast/functions/abs'
require 'dentaku'

describe 'Dentaku::AST::Function::Abs' do
  it 'returns the absolute value of number' do
    result = Dentaku('ABS(-4.2)')
    expect(result).to eq(4.2)
  end

  it 'returns the correct value for positive number' do
    result = Dentaku('ABS(1.3)')
    expect(result).to eq(1.3)
  end

  it 'returns the correct value for zero' do
    result = Dentaku('ABS(0)')
    expect(result).to eq(0)
  end

  context 'checking errors' do
    it 'raises an error if argument is not numeric' do
      expect { Dentaku!("ABS(2020-1-1)") }.to raise_error(Dentaku::ArgumentError)
    end
  end
end
