require 'spec_helper'
require 'dentaku'
require 'dentaku/humanize_visitor'

describe Dentaku::HumanizeVisitor do
  let(:calculator) { Dentaku::Calculator.new }

  def humanize(expression, values = {})
    described_class.new(calculator.ast(expression), values).to_s
  end

  it 'verbalizes comparison operators' do
    expect(humanize('a >= 5')).to eq('a is greater than or equal to 5')
    expect(humanize('a <= 5')).to eq('a is less than or equal to 5')
    expect(humanize('a > 5')).to eq('a is greater than 5')
    expect(humanize('a < 5')).to eq('a is less than 5')
    expect(humanize('a = 5')).to eq('a equals 5')
    expect(humanize('a != 5')).to eq('a does not equal 5')
  end

  it 'verbalizes logical combinators' do
    repr = humanize('a >= 5 and a <= 10')
    expect(repr).to eq('a is greater than or equal to 5 and a is less than or equal to 10')
  end

  it 'verbalizes arithmetic operators' do
    expect(humanize('1 + 2')).to eq('1 plus 2')
    expect(humanize('3 - 1')).to eq('3 minus 1')
    expect(humanize('2 * 3')).to eq('2 times 3')
    expect(humanize('10 / 2')).to eq('10 divided by 2')
    expect(humanize('2 ^ 3')).to eq('2 to the power of 3')
    expect(humanize('7 % 3')).to eq('7 modulo 3')
  end

  it 'verbalizes negation' do
    expect(humanize('-a')).to eq('negative a')
  end

  it 'substitutes identifiers with provided values' do
    expect(humanize('days >= min and days <= max', min: 5, max: 20))
      .to eq('days is greater than or equal to 5 and days is less than or equal to 20')
  end

  it 'quotes string values used in substitution' do
    expect(humanize('name = expected', expected: 'Buk')).to eq('name equals "Buk"')
  end

  it 'preserves identifiers that have no value' do
    expect(humanize('a + b', a: 1)).to eq('1 plus b')
  end

  it 'verbalizes nil literal' do
    expect(humanize('a = NULL')).to eq('a equals null')
  end

  it 'falls back to PrintVisitor behavior for unmapped nodes' do
    # bitwise still uses words via our mapping
    expect(humanize('1 & 2')).to eq('1 bitwise and 2')
    # function calls retain their printed form
    expect(humanize('IF(a = 1, "yes", "no")')).to eq('IF(a equals 1, "yes", "no")')
  end

  it 'is exposed via Calculator#humanize' do
    result = calculator.humanize('days >= min and days <= max', min: 5, max: 20)
    expect(result).to eq('days is greater than or equal to 5 and days is less than or equal to 20')
  end
end
