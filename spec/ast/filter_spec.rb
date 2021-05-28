require 'spec_helper'
require 'dentaku/ast/functions/filter'
require 'dentaku'

describe Dentaku::AST::Filter do
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
end
