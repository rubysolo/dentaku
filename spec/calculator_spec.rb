require 'dentaku/calculator'

describe Dentaku::Calculator do
  let(:calculator)  { described_class.new }
  let(:with_memory) { described_class.new.store(apples: 3) }

  it 'evaluates an expression' do
    expect(calculator.evaluate('7+3')).to eq(10)
    expect(calculator.evaluate('2 -1')).to eq(1)
    expect(calculator.evaluate('-1 + 2')).to eq(1)
    expect(calculator.evaluate('1 - 2')).to eq(-1)
    expect(calculator.evaluate('1 - - 2')).to eq(3)
    expect(calculator.evaluate('-1 - - 2')).to eq(1)
    expect(calculator.evaluate('1 - - - 2')).to eq(-1)
    expect(calculator.evaluate('(-1 + 2)')).to eq(1)
    expect(calculator.evaluate('-(1 + 2)')).to eq(-3)
    expect(calculator.evaluate('2 ^ - 1')).to eq(0.5)
    expect(calculator.evaluate('2 ^ -(3 - 2)')).to eq(0.5)
    expect(calculator.evaluate('(2 + 3) - 1')).to eq(4)
    expect(calculator.evaluate('(-2 + 3) - 1')).to eq(0)
    expect(calculator.evaluate('(-2 - 3) - 1')).to eq(-6)
    expect(calculator.evaluate('1 + -2 ^ 2')).to eq(-3)
    expect(calculator.evaluate('3 + -num', num: 2)).to eq(1)
    expect(calculator.evaluate('-num + 3', num: 2)).to eq(1)
    expect(calculator.evaluate('10 ^ 2')).to eq(100)
    expect(calculator.evaluate('0 * 10 ^ -5')).to eq(0)
    expect(calculator.evaluate('3 + 0 * -3')).to eq(3)
    expect(calculator.evaluate('3 + 0 / -3')).to eq(3)
  end

  describe 'memory' do
    it { expect(calculator).to be_empty }
    it { expect(with_memory).not_to be_empty   }
    it { expect(with_memory.clear).to be_empty }

    it 'discards local values' do
      expect(calculator.evaluate('pears * 2', pears: 5)).to eq(10)
      expect(calculator).to be_empty
    end

    it 'can store the value `false`' do
      calculator.store('i_am_false', false)
      expect(calculator.evaluate!('i_am_false')).to eq false
    end

    it 'can store multiple values' do
      calculator.store(first: 1, second: 2)
      expect(calculator.evaluate!('first')).to eq 1
      expect(calculator.evaluate!('second')).to eq 2
    end
  end

  describe 'dependencies' do
    it "finds dependencies in a generic statement" do
      expect(calculator.dependencies("bob + dole / 3")).to eq(['bob', 'dole'])
    end

    it "doesn't consider variables in memory as dependencies" do
      expect(with_memory.dependencies("apples + oranges")).to eq(['oranges'])
    end
  end

  describe 'solve!' do
    it "evaluates properly with variables, even if some in memory" do
      expect(with_memory.solve!(
        weekly_fruit_budget: "weekly_apple_budget + pear * 4",
        weekly_apple_budget: "apples * 7",
        pear: "1"
      )).to eq(pear: 1, weekly_apple_budget: 21, weekly_fruit_budget: 25)
    end

    it "preserves hash keys" do
      expect(calculator.solve!(
        'meaning_of_life' => 'age + kids',
        'age'  => 40,
        'kids' =>  2
      )).to eq('age' => 40, 'kids' => 2, 'meaning_of_life' => 42)
    end

    it "lets you know about a cycle if one occurs" do
      expect do
        calculator.solve!(health: "happiness", happiness: "health")
      end.to raise_error (TSort::Cyclic)
    end

    it 'is case-insensitive' do
      result = with_memory.solve!(total_fruit: "Apples + pears", pears: 10)
      expect(result[:total_fruit]).to eq 13
    end

    it "lets you know if a variable is unbound" do
      expect {
        calculator.solve!(more_apples: "apples + 1")
      }.to raise_error(Dentaku::UnboundVariableError)
    end
  end

  describe 'solve' do
    it "returns :undefined when variables are unbound" do
      expressions = {more_apples: "apples + 1"}
      expect(calculator.solve(expressions)).to eq(more_apples: :undefined)
    end

    it "allows passing in a custom value to an error handler" do
      expressions = {more_apples: "apples + 1"}
      expect(calculator.solve(expressions) { :foo })
        .to eq(more_apples: :foo)
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
      expect(error.unbound_variables).to eq ['foo']
    end
    expect(calculator.evaluate(unbound)).to be_nil
    expect(calculator.evaluate(unbound) { :bar }).to eq :bar
    expect(calculator.evaluate(unbound) { |e| e }).to eq unbound
  end

  it 'evaluates unbound statements given a binding in memory' do
    expect(calculator.evaluate('foo * 1.5', foo: 2)).to eq(3)
    expect(calculator.bind(monkeys: 3).evaluate('monkeys < 7')).to be_truthy
    expect(calculator.evaluate('monkeys / 1.5')).to eq(2)
  end

  it 'rebinds for each evaluation' do
    expect(calculator.evaluate('foo * 2', foo: 2)).to eq(4)
    expect(calculator.evaluate('foo * 2', foo: 4)).to eq(8)
  end

  it 'accepts strings or symbols for binding keys' do
    expect(calculator.evaluate('foo * 2', foo: 2)).to eq(4)
    expect(calculator.evaluate('foo * 2', 'foo' => 4)).to eq(8)
  end

  it 'accepts digits in identifiers' do
    expect(calculator.evaluate('foo1 * 2', foo1: 2)).to eq(4)
    expect(calculator.evaluate('foo1 * 2', 'foo1' => 4)).to eq(8)
    expect(calculator.evaluate('1foo * 2', '1foo' => 2)).to eq(4)
    expect(calculator.evaluate('fo1o * 2', fo1o: 4)).to eq(8)
  end

  it 'compares string literals with string variables' do
    expect(calculator.evaluate('fruit = "apple"', fruit: 'apple')).to be_truthy
    expect(calculator.evaluate('fruit = "apple"', fruit: 'pear')).to be_falsey
  end

  it 'performs case-sensitive comparison' do
    expect(calculator.evaluate('fruit = "Apple"', fruit: 'apple')).to be_falsey
    expect(calculator.evaluate('fruit = "Apple"', fruit: 'Apple')).to be_truthy
  end

  it 'allows binding logical values' do
    expect(calculator.evaluate('some_boolean AND 7 > 5', some_boolean: true)).to be_truthy
    expect(calculator.evaluate('some_boolean AND 7 < 5', some_boolean: true)).to be_falsey
    expect(calculator.evaluate('some_boolean AND 7 > 5', some_boolean: false)).to be_falsey

    expect(calculator.evaluate('some_boolean OR 7 > 5', some_boolean: true)).to be_truthy
    expect(calculator.evaluate('some_boolean OR 7 < 5', some_boolean: true)).to be_truthy
    expect(calculator.evaluate('some_boolean OR 7 < 5', some_boolean: false)).to be_falsey
  end

  describe 'functions' do
    it 'include IF' do
      expect(calculator.evaluate('if(foo < 8, 10, 20)', foo: 2)).to eq(10)
      expect(calculator.evaluate('if(foo < 8, 10, 20)', foo: 9)).to eq(20)
      expect(calculator.evaluate('if (foo < 8, 10, 20)', foo: 2)).to eq(10)
      expect(calculator.evaluate('if (foo < 8, 10, 20)', foo: 9)).to eq(20)
    end

    it 'include ROUND' do
      expect(calculator.evaluate('round(8.2)')).to eq(8)
      expect(calculator.evaluate('round(8.8)')).to eq(9)
      expect(calculator.evaluate('round(8.75, 1)')).to eq(BigDecimal.new('8.8'))

      expect(calculator.evaluate('ROUND(apples * 0.93)', { apples: 10 })).to eq(9)
    end

    it 'include NOT' do
      expect(calculator.evaluate('NOT(some_boolean)', some_boolean: true)).to be_falsey
      expect(calculator.evaluate('NOT(some_boolean)', some_boolean: false)).to be_truthy

      expect(calculator.evaluate('NOT(some_boolean) AND 7 > 5', some_boolean: true)).to be_falsey
      expect(calculator.evaluate('NOT(some_boolean) OR 7 < 5', some_boolean: false)).to be_truthy
    end

    it 'evaluates functions with negative numbers' do
      expect(calculator.evaluate('if (-1 < 5, -1, 5)')).to eq(-1)
      expect(calculator.evaluate('if (-1 = -1, -1, 5)')).to eq(-1)
      expect(calculator.evaluate('round(-1.23, 1)')).to eq(BigDecimal.new('-1.2'))
      expect(calculator.evaluate('NOT(some_boolean) AND -1 > 3', some_boolean: true)).to be_falsey
    end
  end

  describe 'math functions' do
    Math.methods(false).each do |method|
      it method do
        if Math.method(method).arity == 2
          expect(calculator.evaluate("#{method}(1,2)")).to eq Math.send(method, 1, 2)
        else
          expect(calculator.evaluate("#{method}(1)")).to eq Math.send(method, 1)
        end
      end
    end
  end
end
