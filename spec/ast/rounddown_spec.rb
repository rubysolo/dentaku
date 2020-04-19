require 'spec_helper'
require 'dentaku/ast/functions/rounddown'
require 'dentaku'

describe 'Dentaku::AST::Function::Round' do
  it 'returns the rounded value' do
    result = Dentaku('ROUNDDOWN(1.8)')
    expect(result).to eq(1)
  end

  it 'returns the rounded value to the given precision' do
    result = Dentaku('ROUNDDOWN(x, y)', x: 1.8453, y: 3)
    expect(result).to eq(1.845)
  end

  it 'returns the rounded value to the given precision, also with strings' do
    result = Dentaku('ROUNDDOWN(x, y)', x: '1.8453', y: '3')
    expect(result).to eq(1.845)
  end

  it 'returns the rounded value to the given precision, also with nil' do
    result = Dentaku('ROUNDDOWN(x, y)', x: '1.8453', y: nil)
    expect(result).to eq(1)
  end

  context 'checking errors' do
    it 'raises an error if first argument is not numeric' do
      expect { Dentaku!("ROUND(2020-1-1, 0)") }.to raise_error(Dentaku::ArgumentError)
    end

    it 'raises an error if places is not numeric' do
      expect { Dentaku!("ROUND(1.8, 2020-1-1)") }.to raise_error(Dentaku::ArgumentError)
    end
  end
end
