require 'spec_helper'
require 'dentaku/ast/functions/any'
require 'dentaku'

describe Dentaku::AST::Any do
  let(:calculator) { Dentaku::Calculator.new }

  it 'performs ANY operation' do
    result = Dentaku('ANY(vals, val, val > 1)', vals: [1, 2, 3])
    expect(result).to eq(true)
  end

  it 'works with a single value if needed for some reason' do
    result = Dentaku('ANY(vals, val, val > 1)', vals: 1)
    expect(result).to eq(false)

    result = Dentaku('ANY(vals, val, val > 1)', vals: 2)
    expect(result).to eq(true)
  end

  it 'raises argument error if a string is passed as identifier' do
    expect { calculator.evaluate!('ANY({1, 2, 3}, "val", val % 2 == 0)') }.to raise_error(Dentaku::ParseError)
  end

  it 'treats missing keys in hashes as NULL in permissive mode' do
    expect(
      calculator.evaluate('ANY(items, item, item.value)', items: [{value: 1}, {}])
    ).to be_truthy
  end

  it 'raises an error if accessing a missing key in a hash in strict mode' do
    expect {
      calculator.evaluate!('ANY(items, item, item.value)', items: [{}, {value: 1}])
    }.to raise_error(Dentaku::UnboundVariableError)
  end
end
