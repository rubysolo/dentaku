require 'spec_helper'
require 'dentaku/ast/functions/map'
require 'dentaku'

describe Dentaku::AST::Map do
  it 'operates on each value in an array' do
    result = Dentaku('SUM(MAP(vals, val, val + 1))', vals: [1, 2, 3])
    expect(result).to eq(9)
  end

  it 'works with an empty array' do
    result = Dentaku('MAP(vals, val, val + 1)', vals: [])
    expect(result).to eq([])
  end
end
