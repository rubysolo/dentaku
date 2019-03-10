require 'spec_helper'
require 'dentaku'
require 'dentaku/ast/functions/and'

describe 'Dentaku::AST::And' do
  let(:calculator) { Dentaku::Calculator.new }

  it 'returns false if any of the arguments is false' do
    result = Dentaku('AND(1 = 1, 0 = 1)')
    expect(result).to eq(false)
  end

  it 'supports nested expressions' do
    result = Dentaku('AND(y = 1, x = 1)', x: 1, y: 2)
    expect(result).to eq(false)
  end

  it 'returns true if all of the arguments are true' do
    result = Dentaku('AND(1 = 1, "2" = "2", true = true, true)')
    expect(result).to eq(true)
  end

  it 'returns true if all nested AND functions return true' do
    result = Dentaku('AND(AND(1 = 1), AND(true != false, AND(true)))')
    expect(result).to eq(true)
  end

  it 'raises an error if no arguments are passed' do
    expect { calculator.evaluate!('AND()') }.to raise_error(Dentaku::ArgumentError)
  end

  it 'raises an error if a non logical argument is passed' do
    expect { calculator.evaluate!('AND("r")') }.to raise_error(Dentaku::ArgumentError)
  end
end
