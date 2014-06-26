require 'dentaku/tokenizer'

describe Dentaku::Tokenizer do
  let(:tokenizer) { described_class.new }

  it 'should handle an empty expression' do
    tokenizer.tokenize('').should be_empty
  end

  it 'should tokenize addition' do
    tokens = tokenizer.tokenize('1+1')
    tokens.map(&:category).should eq([:numeric, :operator, :numeric])
    tokens.map(&:value).should eq([1, :add, 1])
  end

  it 'should ignore whitespace' do
    tokens = tokenizer.tokenize('1     / 1     ')
    tokens.map(&:category).should eq([:numeric, :operator, :numeric])
    tokens.map(&:value).should eq([1, :divide, 1])
  end

  it 'should handle floating point' do
    tokens = tokenizer.tokenize('1.5 * 3.7')
    tokens.map(&:category).should eq([:numeric, :operator, :numeric])
    tokens.map(&:value).should eq([1.5, :multiply, 3.7])
  end

  it 'should not require leading zero' do
    tokens = tokenizer.tokenize('.5 * 3.7')
    tokens.map(&:category).should eq([:numeric, :operator, :numeric])
    tokens.map(&:value).should eq([0.5, :multiply, 3.7])
  end

  it 'should accept arbitrary identifiers' do
    tokens = tokenizer.tokenize('monkeys > 1500')
    tokens.map(&:category).should eq([:identifier, :comparator, :numeric])
    tokens.map(&:value).should eq([:monkeys, :gt, 1500])
  end

  it 'should recognize double-quoted strings' do
    tokens = tokenizer.tokenize('animal = "giraffe"')
    tokens.map(&:category).should eq([:identifier, :comparator, :string])
    tokens.map(&:value).should eq([:animal, :eq, 'giraffe'])
  end

  it 'should recognize single-quoted strings' do
    tokens = tokenizer.tokenize("animal = 'giraffe'")
    tokens.map(&:category).should eq([:identifier, :comparator, :string])
    tokens.map(&:value).should eq([:animal, :eq, 'giraffe'])
  end

  it 'should match "<=" before "<"' do
    tokens = tokenizer.tokenize('perimeter <= 7500')
    tokens.map(&:category).should eq([:identifier, :comparator, :numeric])
    tokens.map(&:value).should eq([:perimeter, :le, 7500])
  end

  it 'should match "and" for logical expressions' do
    tokens = tokenizer.tokenize('octopi <= 7500 AND sharks > 1500')
    tokens.map(&:category).should eq([:identifier, :comparator, :numeric, :combinator, :identifier, :comparator, :numeric])
    tokens.map(&:value).should eq([:octopi, :le, 7500, :and, :sharks, :gt, 1500])
  end

  it 'should match "or" for logical expressions' do
    tokens = tokenizer.tokenize('size < 3 or admin = 1')
    tokens.map(&:category).should eq([:identifier, :comparator, :numeric, :combinator, :identifier, :comparator, :numeric])
    tokens.map(&:value).should eq([:size, :lt, 3, :or, :admin, :eq, 1])
  end

  it 'should detect unbalanced parentheses' do
    lambda { tokenizer.tokenize('(5+3') }.should raise_error
    lambda { tokenizer.tokenize(')')    }.should raise_error
  end

  it 'should recognize identifiers that share initial substrings with combinators' do
    tokens = tokenizer.tokenize('andover < 10')
    tokens.length.should eq(3)
    tokens.map(&:category).should eq([:identifier, :comparator, :numeric])
    tokens.map(&:value).should eq([:andover, :lt, 10])
  end

  describe 'functions' do
    it 'include IF' do
      tokens = tokenizer.tokenize('if(x < 10, y, z)')
      tokens.length.should eq(10)
      tokens.map(&:category).should eq([:function, :grouping, :identifier, :comparator, :numeric, :grouping, :identifier, :grouping, :identifier, :grouping])
      tokens.map(&:value).should eq([:if, :open, :x, :lt, 10, :comma, :y, :comma, :z, :close])
    end

    it 'include ROUND/UP/DOWN' do
      tokens = tokenizer.tokenize('round(8.2)')
      tokens.length.should eq(4)
      tokens.map(&:category).should eq([:function, :grouping, :numeric, :grouping])
      tokens.map(&:value).should eq([:round, :open, BigDecimal.new('8.2'), :close])

      tokens = tokenizer.tokenize('round(8.75, 1)')
      tokens.length.should eq(6)
      tokens.map(&:category).should eq([:function, :grouping, :numeric, :grouping, :numeric, :grouping])
      tokens.map(&:value).should eq([:round, :open, BigDecimal.new('8.75'), :comma, 1, :close])

      tokens = tokenizer.tokenize('ROUNDUP(8.2)')
      tokens.length.should eq(4)
      tokens.map(&:category).should eq([:function, :grouping, :numeric, :grouping])
      tokens.map(&:value).should eq([:roundup, :open, BigDecimal.new('8.2'), :close])

      tokens = tokenizer.tokenize('RoundDown(8.2)')
      tokens.length.should eq(4)
      tokens.map(&:category).should eq([:function, :grouping, :numeric, :grouping])
      tokens.map(&:value).should eq([:rounddown, :open, BigDecimal.new('8.2'), :close])
    end

    it 'include NOT' do
      tokens = tokenizer.tokenize('not(8 < 5)')
      tokens.length.should eq(6)
      tokens.map(&:category).should eq([:function, :grouping, :numeric, :comparator, :numeric, :grouping])
      tokens.map(&:value).should eq([:not, :open, 8, :lt, 5, :close])
    end
  end
end
