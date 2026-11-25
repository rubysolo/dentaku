require 'dentaku/print_visitor'
require 'dentaku/tokenizer'
require 'dentaku/parser'

describe Dentaku::PrintVisitor do
  it 'prints a representation of an AST' do
    repr = roundtrip('5+4')
    expect(repr).to eq('5 + 4')
  end

  it 'handles grouping correctly' do
    formula = '10 - (0 - 10)'
    repr = roundtrip(formula)
    expect(repr).to eq(formula)
  end

  it 'quotes string literals' do
    repr = roundtrip('Concat(\'a\',   "B")')
    expect(repr).to eq('CONCAT("a", "B")')
  end

  it 'handles unary operations on literals' do
    repr = roundtrip('- 4')
    expect(repr).to eq('-4')
  end

  it 'handles unary operations on trees' do
    repr = roundtrip('- (5 + 5)')
    expect(repr).to eq('-(5 + 5)')
  end

  it 'handles a complex arithmetic expression' do
    repr = roundtrip('(((1 + 7) * (8 ^ 2)) / - (3.0 - apples))')
    expect(repr).to eq('(1 + 7) * 8 ^ 2 / -(3.0 - apples)')
  end

  it 'handles a complex logical expression' do
    repr = roundtrip('1 < 2 and 3 <= 4 or 5 > 6 AND 7 >= 8 OR 9 != 10 and true')
    expect(repr).to eq('1 < 2 and 3 <= 4 or 5 > 6 and 7 >= 8 or 9 != 10 and true')
  end

  it 'handles a function call' do
    repr = roundtrip('IF(a[0] = NULL, "five", \'seven\')')
    expect(repr).to eq('IF(a[0] = NULL, "five", "seven")')
  end

  it 'handles member access' do
    expect(roundtrip('a[0].b.c + 1')).to eq('a[0].b.c + 1')
    expect(roundtrip('FILTER(xs, x, x.y > 1)[0].y')).to eq('FILTER(xs, x, x.y > 1)[0].y')
  end

  it 'groups anything but accesses and function calls before member access' do
    [
      '(a + b).c',
      '(user).Name',
      '("abc").x',
      '(1).x',
      '(CASE 1 WHEN 1 THEN users[0] END).name',
      'IF(a, b, c).d',
      'a[0].b.c'
    ].each do |formula|
      expect(roundtrip(formula)).to eq(formula)
      expect(roundtrip(roundtrip(formula))).to eq(formula)
    end
  end

  it 'groups anything but variables, arrays, accesses and function calls before an index' do
    [
      '(a + b)[0]',
      '(-(a))[0]',
      '("abc")[0]',
      '(CASE 1 WHEN 1 THEN a END)[0]',
      'a[0]',
      'a[0][1]',
      'a[b[0]]',
      'FILTER(a, x, x > 1)[0]',
      '{10, 20, 30}[0]',
      'users[0].name[0]'
    ].each do |formula|
      expect(roundtrip(formula)).to eq(formula)
      expect(roundtrip(roundtrip(formula))).to eq(formula)
    end
  end

  it 'keeps the meaning of a grouped index' do
    calculator = Dentaku::Calculator.new
    data = { a: [5, 6], b: [1, 2] }
    printed = described_class.new(calculator.ast('(a + b)[0]')).to_s
    expect(calculator.evaluate!(printed, data)).to eq(calculator.evaluate!('(a + b)[0]', data))
  end

  it 'prints array literals as they are written' do
    ['{1, 2}', '{}', '{a, b}', '{{1}, {2, 3}}', '{"x", 1 + 2}', 'SUM({1, 2, x})'].each do |formula|
      expect(roundtrip(formula)).to eq(formula)
    end
  end

  it 'keeps the lookup rules when grouping a variable' do
    calculator = Dentaku::Calculator.new
    data = { user: { 'Name' => 'y', 'name' => 'x' } }
    printed = described_class.new(calculator.ast('(user).Name')).to_s
    expect(calculator.evaluate!(printed, data)).to eq(calculator.evaluate!('(user).Name', data))
  end

  it 'handles a case statement' do
    repr = roundtrip('case (a % 5) when 0 then a else b end')
    expect(repr).to eq('CASE a % 5 WHEN 0 THEN a ELSE b END')
  end

  it 'prints a case statement that can be re-parsed' do
    repr = roundtrip('case (a % 5) when 0 then a else b end')
    expect(roundtrip(repr)).to eq(repr)
  end

  it 'handles a bitwise operators' do
    repr = roundtrip('0xCAFE & 0xDECAF | 0xBEEF')
    expect(repr).to eq('0xCAFE & 0xDECAF | 0xBEEF')
  end

  it 'handles a datetime literal' do
    repr = roundtrip('2017-12-24 23:59:59')
    expect(repr).to eq('2017-12-24 23:59:59')
  end

  it 'handles XOR and NOT operators' do
    expect(roundtrip('a XOR b')).to eq('a xor b')
    expect(roundtrip('!a AND NOT b')).to eq('not a and not b')
    expect(roundtrip('!(a AND b)')).to eq('not (a and b)')
    expect(roundtrip('NOT a = b')).to eq('not a = b')
    expect(roundtrip('NOT NOT a')).to eq('not (not a)')
  end

  it 'handles a percentage in a formula' do
    repr = roundtrip('((3*4%) * 0.001)')
    expect(repr).to eq('3 * 4% * 0.001')
  end

  private

  def roundtrip(string)
    described_class.new(parsed(string)).to_s
  end

  def parsed(string)
    tokens = Dentaku::Tokenizer.new.tokenize(string)
    Dentaku::Parser.new(tokens).parse
  end
end
