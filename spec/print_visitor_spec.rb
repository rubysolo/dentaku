require 'dentaku/print_visitor'
require 'dentaku/tokenizer'
require 'dentaku/parser'

describe Dentaku::PrintVisitor do
  it 'prints a representation of an AST' do
    repr = roundtrip('5+4')
    expect(repr).to eq('5 + 4')
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

  it 'handles a case statement' do
    repr = roundtrip('case (a % 5) when 0 then a else b end')
    expect(repr).to eq('CASE a % 5 WHEN 0 THEN a ELSE b END')
  end

  it 'handles a bitwise operators' do
    repr = roundtrip('0xCAFE & 0xDECAF | 0xBEEF')
    expect(repr).to eq('0xCAFE & 0xDECAF | 0xBEEF')
  end

  it 'handles a datetime literal' do
    repr = roundtrip('2017-12-24 23:59:59')
    expect(repr).to eq('2017-12-24 23:59:59')
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
