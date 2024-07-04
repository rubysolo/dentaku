require 'spec_helper'
require 'dentaku/ast/functions/pluck'
require 'dentaku'

describe Dentaku::AST::Pluck do
  let(:calculator) { Dentaku::Calculator.new }

  it 'operates on each value in an array' do
    result = Dentaku('PLUCK(users, age)', users: [
      {name: "Bob",  age: 44},
      {name: "Jane", age: 27}
    ])
    expect(result).to eq([44, 27])
  end

  it 'allows specifying a default for missing values' do
    result = Dentaku!('PLUCK(users, age, -1)', users: [
      {name: "Bob"},
      {name: "Jane", age: 27}
    ])
    expect(result).to eq([-1, 27])
  end

  it 'returns nil if pluck key is missing from a hash' do
    result = Dentaku!('PLUCK(users, age)', users: [
      {name: "Bob"},
      {name: "Jane", age: 27}
    ])
    expect(result).to eq([nil, 27])
  end

  it 'works with an empty array' do
    result = Dentaku('PLUCK(users, age)', users: [])
    expect(result).to eq([])
  end

  it 'raises argument error if a string is passed as identifier' do
    expect do Dentaku.evaluate!('PLUCK(users, "age")', users: [
      {name: "Bob",  age: 44},
      {name: "Jane", age: 27}
    ]) end.to raise_error(Dentaku::ParseError, 'PLUCK() requires second argument to be an identifier')
  end

  it 'raises argument error if a non array of hashes is passed as collection' do
    expect { calculator.evaluate!('PLUCK({1, 2, 3}, age)') }.to raise_error(
      Dentaku::ArgumentError, 'PLUCK() requires first argument to be an array of hashes'
    )
  end
end
