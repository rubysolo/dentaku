require 'spec_helper'
require 'dentaku'
require 'dentaku/ast/functions/or'

describe 'Dentaku::AST::Xor' do
  let(:calculator) { Dentaku::Calculator.new }

  it 'returns false if all of the arguments are false' do
    result = Dentaku('XOR(false, false)')
    expect(result).to eq(false)
  end

  it 'returns true if only one of the arguments is true' do
    result = Dentaku('XOR(false, true)')
    expect(result).to eq(true)
  end

  it 'returns false if more than one of the arguments is true' do
    result = Dentaku('XOR(false, true, true)')
    expect(result).to eq(false)
  end

  it 'supports nested expressions' do
    result = Dentaku('XOR(y = 1, x = 1)', x: 1, y: 2)
    expect(result).to eq(true)
  end

  it 'raises an error if no arguments are passed' do
    expect { calculator.evaluate!('XOR()') }.to raise_error(Dentaku::ParseError)
  end

  it 'raises an error if a non logical argument is passed' do
    expect { calculator.evaluate!('XOR("r")') }.to raise_error(Dentaku::ArgumentError)
  end
end
