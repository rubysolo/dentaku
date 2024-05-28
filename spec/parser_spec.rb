require 'spec_helper'
require 'dentaku/token'
require 'dentaku/tokenizer'
require 'dentaku/parser'

describe Dentaku::Parser do
  it 'parses an integer literal' do
    node = parse('5')
    expect(node.value).to eq(5)
  end

  it 'performs simple addition' do
    node = parse('5 + 4')
    expect(node.value).to eq(9)
  end

  it 'compares two numbers' do
    node = parse('5 < 4')
    expect(node.value).to eq(false)
  end

  it 'calculates unary percentage' do
    node = parse('5%')
    expect(node.value).to eq(0.05)
  end

  it 'calculates bitwise OR' do
    node = parse('2|3')
    expect(node.value).to eq(3)
  end

  it 'performs multiple operations in one stream' do
    node = parse('5 * 4 + 3')
    expect(node.value).to eq(23)
  end

  it 'respects order of operations' do
    node = parse('5 + 4*3')
    expect(node.value).to eq(17)
  end

  it 'respects grouping by parenthesis' do
    node = parse('(5 + 4) * 3')
    expect(node.value).to eq(27)
  end

  it 'evaluates functions' do
    node = parse('IF(5 < 4, 3, 2)')
    expect(node.value).to eq(2)
  end

  it 'represents formulas with variables' do
    node = parse('5 * x')
    expect { node.value }.to raise_error(Dentaku::UnboundVariableError)
    expect(node.value("x" => 3)).to eq(15)
  end

  it 'evaluates access into data structures' do
    node = parse('a[1]')
    expect { node.value }.to raise_error(Dentaku::UnboundVariableError)
    expect(node.value("a" => [1, 2, 3])).to eq(2)
  end

  it 'evaluates boolean expressions' do
    node = parse('true AND false')
    expect(node.value).to eq(false)
  end

  it 'evaluates a case statement' do
    node = parse('CASE x WHEN 1 THEN 2 WHEN 3 THEN 4 END')
    expect(node.value("x" => 3)).to eq(4)
  end

  it 'evaluates a nested case statement with case-sensitivity' do
    node = parse('CASE x WHEN 1 THEN CASE Y WHEN "A" THEN 2 WHEN "B" THEN 3 END END', { case_sensitive: true }, { case_sensitive: true })
    expect(node.value("x" => 1, "y" => "A", "Y" => "B")).to eq(3)
  end

  it 'evaluates arrays' do
    node = parse('{1, 2, 3}')
    expect(node.value).to eq([1, 2, 3])

    node = parse('{}')
    expect(node.value).to eq([])
  end

  context 'invalid expression' do
    it 'raises a parse error for bad math' do
      expect {
        parse("5 * -")
      }.to raise_error(Dentaku::ParseError)
    end

    it 'raises a parse error for bad logic' do
      expect {
        parse("TRUE AND")
      }.to raise_error(Dentaku::ParseError)
    end

    it 'raises a parse error for too many operands' do
      expect {
        parse("IF(1, 0, IF(1, 2, 3, 4))")
      }.to raise_error(Dentaku::ParseError)

      expect {
        parse("CASE a WHEN 1 THEN true ELSE THEN IF(1, 2, 3, 4) END")
      }.to raise_error(Dentaku::ParseError)
    end

    it 'raises a parse error for bad grouping structure' do
      expect {
        parse(",")
      }.to raise_error(Dentaku::ParseError)

      expect {
        parse("5, x")
        described_class.new([five, comma, x]).parse
      }.to raise_error(Dentaku::ParseError)

      expect {
        parse("5 + 5, x")
      }.to raise_error(Dentaku::ParseError)

      expect {
        parse("{1, 2, }")
      }.to raise_error(Dentaku::ParseError)

      expect {
        parse("CONCAT('1', '2', )")
      }.to raise_error(Dentaku::ParseError)
    end

    it 'raises parse errors for malformed case statements' do
      expect {
        parse("CASE a when 'one' then 1")
      }.to raise_error(Dentaku::ParseError)

      expect {
        parse("case a whend 'one' then 1 end")
      }.to raise_error(Dentaku::ParseError)

      expect {
        parse("CASE a WHEN 'one' THEND 1 END")
      }.to raise_error(Dentaku::ParseError)

      expect {
        parse("CASE a when 'one' then end")
      }.to raise_error(Dentaku::ParseError)
    end

    it 'raises a parse error when trying to access an undefined function' do
      expect {
        parse("undefined()")
      }.to raise_error(Dentaku::ParseError)
    end
  end

  it "evaluates explicit 'NULL' as nil" do
    node = parse("NULL")
    expect(node.value).to eq(nil)
  end

  private

  def parse(expr, parser_options = {}, tokenizer_options = {})
    tokens = Dentaku::Tokenizer.new.tokenize(expr, tokenizer_options)
    described_class.new(tokens, parser_options).parse
  end
end
