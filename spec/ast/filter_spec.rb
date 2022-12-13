require 'spec_helper'
require 'dentaku/ast/functions/filter'
require 'dentaku'

describe Dentaku::AST::Filter do
  let(:calculator) { Dentaku::Calculator.new }
  it 'excludes unmatched values' do
    result = Dentaku('SUM(FILTER(vals, val, val > 1))', vals: [1, 2, 3])
    expect(result).to eq(5)
  end

  it 'works with a single value if needed for some reason' do
    result = Dentaku('FILTER(vals, val, val > 1)', vals: 1)
    expect(result).to eq([])

    result = Dentaku('FILTER(vals, val, val > 1)', vals: 2)
    expect(result).to eq([2])
  end

  it 'raises argument error if a string is passed as identifier' do
    expect { calculator.evaluate!('FILTER({1, 2, 3}, "val", val % 2 == 0)') }.to raise_error(
      Dentaku::ParseError, 'FILTER() requires second argument to be an identifier'
    )
  end
end
