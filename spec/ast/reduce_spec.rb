require 'spec_helper'
require 'dentaku/ast/functions/reduce'
require 'dentaku'

describe Dentaku::AST::Reduce do
  let(:calculator) { Dentaku::Calculator.new }

  it 'performs REDUCE operation with initial value' do
    result = Dentaku('REDUCE(vals, memo, val, CONCAT(memo, val), "hello")', vals: ["wo", "rl", "d"])
    expect(result).to eq("helloworld")
  end

  it 'performs REDUCE operation without initial value' do
    result = Dentaku('REDUCE(vals, memo, val, CONCAT(memo, val))', vals: ["wo", "rl", "d"])
    expect(result).to eq("world")
  end

  it 'raises argument error if a string is passed as identifier' do
    expect { calculator.evaluate!('REDUCE({1, 2, 3}, memo, "val", memo + val)') }.to raise_error(Dentaku::ParseError)
    expect { calculator.evaluate!('REDUCE({1, 2, 3}, "memo", val, memo + val)') }.to raise_error(Dentaku::ParseError)
  end
end
