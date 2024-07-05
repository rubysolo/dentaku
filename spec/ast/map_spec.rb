require 'spec_helper'
require 'dentaku/ast/functions/map'
require 'dentaku'

describe Dentaku::AST::Map do
  let(:calculator) { Dentaku::Calculator.new }

  it 'operates on each value in an array' do
    result = Dentaku('SUM(MAP(vals, val, val + 1))', vals: [1, 2, 3])
    expect(result).to eq(9)
  end

  it 'works with an empty array' do
    result = Dentaku('MAP(vals, val, val + 1)', vals: [])
    expect(result).to eq([])
  end

  it 'works with a single value if needed for some reason' do
    result = Dentaku('MAP(vals, val, val + 1)', vals: 1)
    expect(result).to eq([2])
  end

  it 'raises argument error if a string is passed as identifier' do
    expect { calculator.evaluate!('MAP({1, 2, 3}, "val", val + 1)') }.to raise_error(
      Dentaku::ParseError,  'MAP() requires second argument to be an identifier'
    )
  end

  it 'treats missing keys in hashes as NULL in permissive mode' do
    expect(
      calculator.evaluate('MAP(items, item, item.value)', items: [{value: 1}, {}])
    ).to eq([1, nil])
  end

  it 'raises an error if accessing a missing key in a hash in strict mode' do
    expect {
      calculator.evaluate!('MAP(items, item, item.value)', items: [{value: 1}, {}])
    }.to raise_error(Dentaku::UnboundVariableError)
  end
end
