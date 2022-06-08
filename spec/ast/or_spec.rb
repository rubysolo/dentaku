require 'spec_helper'
require 'dentaku'
require 'dentaku/ast/functions/or'

describe 'Dentaku::AST::Or' do
  let(:calculator) { Dentaku::Calculator.new }

  it 'returns false if all of the arguments are false' do
    result = Dentaku('OR(1 = "2", 0 = 1)')
    expect(result).to eq(false)
  end

  it 'supports nested expressions' do
    result = Dentaku('OR(y = 1, x = 1)', x: 1, y: 2)
    expect(result).to eq(true)
  end

  it 'returns true if any of the arguments is true' do
    result = Dentaku('OR(1 = "1", "2" = "2", true = false, false)')
    expect(result).to eq(true)
  end

  it 'returns true if any nested OR function returns true' do
    result = Dentaku('OR(OR(1 = 0), OR(true = false, OR(true)))')
    expect(result).to eq(true)
  end

  it 'raises an error if no arguments are passed' do
    expect { calculator.evaluate!('OR()') }.to raise_error(Dentaku::ArgumentError)
  end

  it 'raises an error if a non logical argument is passed' do
    expect { calculator.evaluate!('OR("r")') }.to raise_error(Dentaku::ArgumentError)
  end
end
