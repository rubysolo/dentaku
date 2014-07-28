require 'dentaku/calculator'

describe Dentaku::Calculator do
  let(:calculator)  { described_class.new }
  let(:with_memory) { described_class.new.store(:apples => 3) }

  it 'evaluates an expression' do
    expect(calculator.evaluate('7+3')).to eq(10)
  end

  describe 'memory' do
    it { expect(calculator).to be_empty }
    it { expect(with_memory).not_to be_empty   }
    it { expect(with_memory.clear).to be_empty }

    it 'discards local values' do
      expect(calculator.evaluate('pears * 2', :pears => 5)).to eq(10)
      expect(calculator).to be_empty
    end
  end

  it 'evaluates a statement with no variables' do
    expect(calculator.evaluate('5+3')).to eq(8)
    expect(calculator.evaluate('(1+1+1)/3*100')).to eq(100)
  end

  it 'fails to evaluate unbound statements' do
    unbound = 'foo * 1.5'
    expect { calculator.evaluate!(unbound) }.to raise_error(Dentaku::UnboundVariableError)
    expect { calculator.evaluate!(unbound) }.to raise_error do |error|
      expect(error.unbound_variables).to eq [:foo]
    end
    expect(calculator.evaluate(unbound)).to be_nil
    expect(calculator.evaluate(unbound) { :bar }).to eq :bar
    expect(calculator.evaluate(unbound) { |e| e }).to eq unbound
  end

  it 'evaluates unbound statements given a binding in memory' do
    expect(calculator.evaluate('foo * 1.5', :foo => 2)).to eq(3)
    expect(calculator.bind(:monkeys => 3).evaluate('monkeys < 7')).to be_truthy
    expect(calculator.evaluate('monkeys / 1.5')).to eq(2)
  end

  it 'rebinds for each evaluation' do
    expect(calculator.evaluate('foo * 2', :foo => 2)).to eq(4)
    expect(calculator.evaluate('foo * 2', :foo => 4)).to eq(8)
  end

  it 'accepts strings or symbols for binding keys' do
    expect(calculator.evaluate('foo * 2', :foo => 2)).to eq(4)
    expect(calculator.evaluate('foo * 2', 'foo' => 4)).to eq(8)
  end

  it 'accepts digits in identifiers' do
    expect(calculator.evaluate('foo1 * 2', :foo1 => 2)).to eq(4)
    expect(calculator.evaluate('foo1 * 2', 'foo1' => 4)).to eq(8)
    expect(calculator.evaluate('1foo * 2', '1foo' => 2)).to eq(4)
    expect(calculator.evaluate('fo1o * 2', :fo1o => 4)).to eq(8)
  end

  it 'compares string literals with string variables' do
    expect(calculator.evaluate('fruit = "apple"', :fruit => 'apple')).to be_truthy
    expect(calculator.evaluate('fruit = "apple"', :fruit => 'pear')).to be_falsey
  end

  it 'performs case-sensitive comparison' do
    expect(calculator.evaluate('fruit = "Apple"', :fruit => 'apple')).to be_falsey
    expect(calculator.evaluate('fruit = "Apple"', :fruit => 'Apple')).to be_truthy
  end

  it 'allows binding logical values' do
    expect(calculator.evaluate('some_boolean AND 7 > 5', :some_boolean => true)).to be_truthy
    expect(calculator.evaluate('some_boolean AND 7 < 5', :some_boolean => true)).to be_falsey
    expect(calculator.evaluate('some_boolean AND 7 > 5', :some_boolean => false)).to be_falsey

    expect(calculator.evaluate('some_boolean OR 7 > 5', :some_boolean => true)).to be_truthy
    expect(calculator.evaluate('some_boolean OR 7 < 5', :some_boolean => true)).to be_truthy
    expect(calculator.evaluate('some_boolean OR 7 < 5', :some_boolean => false)).to be_falsey

  end

  describe 'functions' do
    it 'include IF' do
      expect(calculator.evaluate('if(foo < 8, 10, 20)', :foo => 2)).to eq(10)
      expect(calculator.evaluate('if(foo < 8, 10, 20)', :foo => 9)).to eq(20)
      expect(calculator.evaluate('if (foo < 8, 10, 20)', :foo => 2)).to eq(10)
      expect(calculator.evaluate('if (foo < 8, 10, 20)', :foo => 9)).to eq(20)
    end

    it 'include ROUND' do
      expect(calculator.evaluate('round(8.2)')).to eq(8)
      expect(calculator.evaluate('round(8.8)')).to eq(9)
      expect(calculator.evaluate('round(8.75, 1)')).to eq(BigDecimal.new('8.8'))

      expect(calculator.evaluate('ROUND(apples * 0.93)', { :apples => 10 })).to eq(9)
    end

    it 'include NOT' do
      expect(calculator.evaluate('NOT(some_boolean)', :some_boolean => true)).to be_falsey
      expect(calculator.evaluate('NOT(some_boolean)', :some_boolean => false)).to be_truthy

      expect(calculator.evaluate('NOT(some_boolean) AND 7 > 5', :some_boolean => true)).to be_falsey
      expect(calculator.evaluate('NOT(some_boolean) OR 7 < 5', :some_boolean => false)).to be_truthy
    end
  end
end
