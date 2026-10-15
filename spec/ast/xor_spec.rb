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

  it 'returns false if an even number of the arguments are true' do
    expect(Dentaku('XOR(false, true, true)')).to eq(false)
    expect(Dentaku('XOR(true, true, true, true)')).to eq(false)
  end

  it 'returns true if an odd number of the arguments are true' do
    expect(Dentaku('XOR(true, true, true)')).to eq(true)
    expect(Dentaku('XOR(true, false, true, true)')).to eq(true)
  end

  it 'matches XOR applied pairwise' do
    [true, false].repeated_permutation(4).each do |a, b, c, d|
      context = { a: a, b: b, c: c, d: d }
      expect(Dentaku('XOR(a, b, c, d)', context))
        .to eq(Dentaku('XOR(XOR(a, b), XOR(c, d))', context))
    end
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
