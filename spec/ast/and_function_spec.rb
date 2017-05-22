require 'spec_helper'
require 'dentaku'
require 'dentaku/ast/functions/and'

describe 'Dentaku::AST::And' do
  it 'returns false if any of the arguments is false' do
    result = Dentaku('AND(1 = 1, 0 = 1)')
    expect(result).to eq false
  end

  it 'returns true if all of the arguments are true' do
    result = Dentaku('AND(1 = 1, "2" = "2", true = true, true)')
    expect(result).to eq true
  end

  it 'returns true if all nested AND functions return true' do
    result = Dentaku('AND(AND(1 = 1), AND(true != false, AND(true)))')
    expect(result).to eq true
  end

  it 'raises an error if no arguments are passed' do
    expect { Dentaku('AND()') }.to raise_error(ArgumentError)
  end

  it 'raises an error if a non logical argument is passed' do
    expect { Dentaku('AND("r")') }.to raise_error(ArgumentError)
  end
end
