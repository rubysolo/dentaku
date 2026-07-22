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
    expect(humanize('a > 5')).to  eq('a is greater than 5')
    expect(humanize('a < 5')).to  eq('a is less than 5')
    expect(humanize('a = 5')).to  eq('a equals 5')
    expect(humanize('a != 5')).to eq('a does not equal 5')
  end

  it 'verbalizes arithmetic operators' do
    expect(humanize('1 + 2')).to eq('1 plus 2')
    expect(humanize('3 - 1')).to eq('3 minus 1')
    expect(humanize('2 * 3')).to eq('2 times 3')
    expect(humanize('10 / 2')).to eq('10 divided by 2')
    expect(humanize('2 ^ 3')).to eq('2 to the power of 3')
    expect(humanize('7 % 3')).to eq('7 modulo 3')
  end

  it 'verbalizes bitwise operators' do
    expect(humanize('1 & 2')).to  eq('1 bitwise and 2')
    expect(humanize('1 | 2')).to  eq('1 bitwise or 2')
    expect(humanize('1 << 2')).to eq('1 shifted left by 2')
    expect(humanize('1 >> 2')).to eq('1 shifted right by 2')
  end

  it 'verbalizes logical combinators' do
    expect(humanize('a >= 5 and a <= 10'))
      .to eq('a is greater than or equal to 5 and a is less than or equal to 10')
    expect(humanize('a < 0 or a > 100')).to eq('a is less than 0 or a is greater than 100')
  end

  it 'verbalizes negation' do
    expect(humanize('-a')).to eq('negative a')
  end

  it 'verbalizes nil literal' do
    expect(humanize('a = NULL')).to eq('a equals null')
  end

  it 'substitutes identifiers with provided values' do
    expect(humanize('days >= min and days <= max', min: 5, max: 20))
      .to eq('days is greater than or equal to 5 and days is less than or equal to 20')
  end

  it 'quotes string values in substitution' do
    expect(humanize('name = expected', expected: 'Buk')).to eq('name equals "Buk"')
  end

  it 'preserves identifiers with no substitution value' do
    expect(humanize('a + b', a: 1)).to eq('1 plus b')
  end

  it 'verbalizes IF' do
    expect(humanize('IF(a > 0, "yes", "no")')).to eq('if a is greater than 0 then "yes" else "no"')
  end

  it 'verbalizes AND function' do
    expect(humanize('AND(a > 0, b > 0)')).to eq('a is greater than 0 and b is greater than 0')
  end

  it 'verbalizes OR function' do
    expect(humanize('OR(a > 0, b > 0)')).to eq('a is greater than 0 or b is greater than 0')
  end

  it 'verbalizes XOR' do
    expect(humanize('XOR(a, b)')).to eq('a exclusive-or b')
  end

  it 'verbalizes NOT' do
    expect(humanize('NOT(a)')).to eq('not a')
  end

  it 'verbalizes SWITCH with default' do
    expect(humanize('SWITCH(x, 1, "one", 2, "two", "other")'))
      .to eq('x switch: when 1 use "one"; when 2 use "two"; otherwise "other"')
  end

  it 'verbalizes SWITCH without default' do
    expect(humanize('SWITCH(x, 1, "one", 2, "two")'))
      .to eq('x switch: when 1 use "one"; when 2 use "two"')
  end

  it 'verbalizes MIN / MAX / SUM / AVG / COUNT' do
    expect(humanize('MIN(a, b, c)')).to   eq('minimum of a, b, c')
    expect(humanize('MAX(a, b)')).to      eq('maximum of a, b')
    expect(humanize('SUM(a, b, c)')).to   eq('sum of a, b, c')
    expect(humanize('AVG(a, b)')).to      eq('average of a, b')
    expect(humanize('COUNT(a, b, c)')).to eq('count of a, b, c')
  end

  it 'verbalizes ABS' do
    expect(humanize('ABS(x)')).to eq('absolute value of x')
  end

  it 'verbalizes ROUND / ROUNDUP / ROUNDDOWN' do
    expect(humanize('ROUND(x, 2)')).to     eq('x rounded to 2 decimal places')
    expect(humanize('ROUNDUP(x, 2)')).to   eq('x rounded up to 2 decimal places')
    expect(humanize('ROUNDDOWN(x, 2)')).to eq('x rounded down to 2 decimal places')
  end

  it 'verbalizes INTERCEPT' do
    expect(humanize('INTERCEPT(xs, ys)')).to eq('linear intercept of xs and ys')
  end

  it 'verbalizes LEFT / RIGHT' do
    expect(humanize('LEFT(s, 3)')).to  eq('first 3 characters of s')
    expect(humanize('RIGHT(s, 3)')).to eq('last 3 characters of s')
  end

  it 'verbalizes MID' do
    expect(humanize('MID(s, 2, 4)')).to eq('4 characters of s starting at position 2')
  end

  it 'verbalizes LEN' do
    expect(humanize('LEN(s)')).to eq('length of s')
  end

  it 'verbalizes FIND' do
    expect(humanize('FIND(needle, haystack)')).to eq('position of needle in haystack')
  end

  it 'verbalizes SUBSTITUTE' do
    expect(humanize('SUBSTITUTE(text, "foo", "bar")')).to eq('text with "foo" replaced by "bar"')
  end

  it 'verbalizes CONCAT' do
    expect(humanize('CONCAT(a, b, c)')).to eq('a, b and c joined')
  end

  it 'verbalizes CONTAINS' do
    expect(humanize('CONTAINS(needle, haystack)')).to eq('haystack contains needle')
  end

  it 'verbalizes CASE' do
    expr = 'CASE x WHEN 1 THEN "one" WHEN 2 THEN "two" ELSE "other" END'
    expect(humanize(expr)).to eq('x case: when 1 then "one" when 2 then "two"; otherwise "other"')
  end

  it 'verbalizes MAP' do
    expect(humanize('MAP(items, x, x * 2)')).to eq('for each x in items: x times 2')
  end

  it 'verbalizes FILTER' do
    expect(humanize('FILTER(items, x, x > 0)')).to eq('filter x in items where x is greater than 0')
  end

  it 'verbalizes ALL' do
    expect(humanize('ALL(items, x, x > 0)')).to eq('all x in items satisfy x is greater than 0')
  end

  it 'verbalizes ANY' do
    expect(humanize('ANY(items, x, x > 0)')).to eq('any x in items satisfies x is greater than 0')
  end

  it 'verbalizes PLUCK' do
    expect(humanize('PLUCK(items, name)')).to eq('values of name from items')
  end

  it 'verbalizes unary Math functions' do
    expect(humanize('SIN(x)')).to  eq('sine of x')
    expect(humanize('COS(x)')).to  eq('cosine of x')
    expect(humanize('TAN(x)')).to  eq('tangent of x')
    expect(humanize('SQRT(x)')).to eq('square root of x')
    expect(humanize('LOG(x)')).to  eq('logarithm of x')
  end

  it 'verbalizes LOG with base' do
    expect(humanize('LOG(x, 10)')).to eq('logarithm of x in base 10')
  end

  it 'verbalizes binary Math functions' do
    expect(humanize('ATAN2(y, x)')).to eq('arctangent of y and x')
    expect(humanize('HYPOT(a, b)')).to eq('hypotenuse of a and b')
  end

  it 'is exposed via Calculator#humanize' do
    result = calculator.humanize('days >= min and days <= max', min: 5, max: 20)
    expect(result).to eq('days is greater than or equal to 5 and days is less than or equal to 20')
  end
end
