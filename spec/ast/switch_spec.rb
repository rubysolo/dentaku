require 'spec_helper'
require 'dentaku/ast/functions/switch'
require 'dentaku'

describe 'Dentaku::AST::Function::Switch' do
  it 'returns the match if present in argumtents' do
    result = Dentaku('SWITCH(1, 1, "one", 2, "two")')
    expect(result).to eq('one')
  end

  it 'returns nil if no match was found' do
    result = Dentaku('SWITCH(3, 1, "one", 2, "two")')
    expect(result).to eq(nil)
  end

  it 'returns the default value if present and no match was found' do
    result = Dentaku('SWITCH(3, 1, "one", 2, "two", "no match")')
    expect(result).to eq('no match')
  end

  it 'returns the first match if multiple matches exist' do
    result = Dentaku('SWITCH(1, 1, "one", 2, "two", 1, "three")')
    expect(result).to eq('one')
  end

  it 'does not return a match where a value matches the search value' do
    result = Dentaku('SWITCH(1, "one", 1, 2, "two", 3)')
    expect(result).to eq(3)
  end
end
