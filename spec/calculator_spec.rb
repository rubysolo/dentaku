require 'spec_helper'
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
    expect(calculator.evaluate('1 + -(2 ^ 2)')).to eq(-3)
    expect(calculator.evaluate('3 + -num', num: 2)).to eq(1)
    expect(calculator.evaluate('-num + 3', num: 2)).to eq(1)
    expect(calculator.evaluate('10 ^ 2')).to eq(100)
    expect(calculator.evaluate('0 * 10 ^ -5')).to eq(0)
    expect(calculator.evaluate('3 + 0 * -3')).to eq(3)
    expect(calculator.evaluate('3 + 0 / -3')).to eq(3)
    expect(calculator.evaluate('15 % 8')).to eq(7)
    expect(calculator.evaluate('(((695759/735000)^(1/(1981-1991)))-1)*1000').round(4)).to eq(5.5018)
    expect(calculator.evaluate('0.253/0.253')).to eq(1)
    expect(calculator.evaluate('0.253/d', d: 0.253)).to eq(1)
    expect(calculator.evaluate('10 + x', x: 'abc')).to be_nil
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

    it 'stores formulas' do
      calculator.store_formula('area', 'length * width')
      expect(calculator.evaluate!('area', length: 5, width: 5)).to eq 25
    end
  end

  describe 'dependencies' do
    it "finds dependencies in a generic statement" do
      expect(calculator.dependencies("bob + dole / 3")).to eq(['bob', 'dole'])
    end

    it "finds dependencies in formula arguments" do
      allow(Dentaku).to receive(:cache_ast?) { true }

      expect(calculator.dependencies("CONCAT(bob, dole)")).to eq(['bob', 'dole'])
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
        pear:                "1"
      )).to eq(pear: 1, weekly_apple_budget: 21, weekly_fruit_budget: 25)
    end

    it "preserves hash keys" do
      expect(calculator.solve!(
        'meaning_of_life' => 'age + kids',
        'age'             => 40,
        'kids'            =>  2
      )).to eq('age' => 40, 'kids' => 2, 'meaning_of_life' => 42)
    end

    it "lets you know about a cycle if one occurs" do
      expect do
        calculator.solve!(health: "happiness", happiness: "health")
      end.to raise_error(TSort::Cyclic)
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

    it 'can reference stored formulas' do
      calculator.store_formula("base_area", "length * width")
      calculator.store_formula("volume", "base_area * height")

      result = calculator.solve!(
        weight: "volume * 5.432",
        height: "3",
        length: "2",
        width:  "length * 2",
      )

      expect(result[:weight]).to eq 130.368
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

    it "solves remainder of expressions with unbound variable" do
      calculator.store(peaches: 1, oranges: 1)
      expressions = { more_apples: "apples + 1", more_peaches: "peaches + 1" }
      result = calculator.solve(expressions)
      expect(calculator.memory).to eq("peaches" => 1, "oranges" => 1)
      expect(result).to eq(
        more_apples: :undefined,
        more_peaches: 2
      )
    end

    it "solves remainder of expressions when one cannot be evaluated" do
      result = calculator.solve(
        conditional: "IF(d != 0, ratio, 0)",
        ratio:       "10/d",
        d:           0,
      )

      expect(result).to eq(
        conditional: 0,
        ratio:       :undefined,
        d:           0,
      )
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

    it 'evaluates functions with stored variables' do
      calculator.store("multi_color" => true, "number_of_sheets" => 5000, "sheets_per_minute_black" => 2000, "sheets_per_minute_color" => 1000)
      result = calculator.evaluate('number_of_sheets / if(multi_color, sheets_per_minute_color, sheets_per_minute_black)')
      expect(result).to eq(5)
    end

    describe 'roundup' do
      it 'should work with one argument' do
        expect(calculator.evaluate('roundup(1.234)')).to eq(2)
      end

      it 'should accept second precision argument like in Office formula' do
        expect(calculator.evaluate('roundup(1.234, 2)')).to eq(1.24)
      end
    end

    describe 'rounddown' do
      it 'should work with one argument' do
        expect(calculator.evaluate('rounddown(1.234)')).to eq(1)
      end

      it 'should accept second precision argument like in Office formula' do
        expect(calculator.evaluate('rounddown(1.234, 2)')).to eq(1.23)
      end
    end
  end

  describe 'explicit NULL' do
    it 'can be used in IF statements' do
      expect(calculator.evaluate('IF(null, 1, 2)')).to eq(2)
    end

    it 'can be used in IF statements when passed in' do
      expect(calculator.evaluate('IF(foo, 1, 2)', foo: nil)).to eq(2)
    end

    it 'nil values are carried across middle terms' do
      results = calculator.solve!(
        choice: 'IF(bar, 1, 2)',
        bar: 'foo',
        foo: nil)
      expect(results).to eq(
        choice: 2,
        bar: nil,
        foo: nil
      )
    end

    it 'raises errors when used in arithmetic operation' do
      expect {
        calculator.solve!(more_apples: "apples + 1", apples: nil)
      }.to raise_error(Dentaku::ArgumentError)
    end
  end

  describe 'case statements' do
    it 'handles complex then statements' do
      formula = <<-FORMULA
      CASE fruit
      WHEN 'apple'
        THEN (1 * quantity)
      WHEN 'banana'
        THEN (2 * quantity)
      END
      FORMULA
      expect(calculator.evaluate(formula, quantity: 3, fruit: 'apple')).to eq(3)
      expect(calculator.evaluate(formula, quantity: 3, fruit: 'banana')).to eq(6)
    end

    it 'handles complex when statements' do
      formula = <<-FORMULA
      CASE number
      WHEN (2 * 2)
        THEN 1
      WHEN (2 * 3)
        THEN 2
      END
      FORMULA
      expect(calculator.evaluate(formula, number: 4)).to eq(1)
      expect(calculator.evaluate(formula, number: 6)).to eq(2)
    end

    it 'throws an exception when no match and there is no default value' do
      formula = <<-FORMULA
      CASE number
      WHEN 42
        THEN 1
      END
      FORMULA
      expect { calculator.evaluate(formula, number: 2) }
        .to raise_error("No block matched the switch value '2'")
    end

    it 'handles a default else statement' do
      formula = <<-FORMULA
      CASE fruit
      WHEN 'apple'
        THEN 1 * quantity
      WHEN 'banana'
        THEN 2 * quantity
      ELSE
        3 * quantity
      END
      FORMULA
      expect(calculator.evaluate(formula, quantity: 1, fruit: 'banana')).to eq(2)
      expect(calculator.evaluate(formula, quantity: 1, fruit: 'orange')).to eq(3)
    end

    it 'handles nested case statements' do
      formula = <<-FORMULA
      CASE fruit
      WHEN 'apple'
        THEN 1 * quantity
      WHEN 'banana'
        THEN
        CASE quantity
        WHEN 1 THEN 2
        WHEN 10 THEN
          CASE type
          WHEN 'organic' THEN 5
          END
        END
      END
      FORMULA
      value = calculator.evaluate(
        formula,
        type: 'organic',
        quantity: 10,
        fruit: 'banana')
      expect(value).to eq(5)
    end

    it 'handles multiple nested case statements' do
      formula = <<-FORMULA
      CASE fruit
      WHEN 'apple'
        THEN
        CASE quantity
        WHEN 2 THEN 3
        END
      WHEN 'banana'
        THEN
        CASE quantity
        WHEN 1 THEN 2
        END
      END
      FORMULA
      value = calculator.evaluate(
        formula,
        quantity: 1,
        fruit: 'banana')
      expect(value).to eq(2)

      value = calculator.evaluate(
        formula,
        quantity: 2,
        fruit: 'apple')
      expect(value).to eq(3)
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

  describe 'disable_cache' do
    before do
      allow(Dentaku).to receive(:cache_ast?) { true }
    end

    it 'disables the AST cache' do
      expect(calculator.disable_cache{ |c| c.cache_ast? }).to be false
    end

    it 'calculates normally' do
      expect(calculator.disable_cache{ |c| c.evaluate("2 + 2") }).to eq(4)
    end
  end

  describe 'clear_cache' do
    before do
      allow(Dentaku).to receive(:cache_ast?) { true }

      calculator.ast("1+1")
      calculator.ast("pineapples * 5")
      calculator.ast("pi * radius ^ 2")

      def calculator.ast_cache
        @ast_cache
      end
    end

    it 'clears all items from cache' do
      expect(calculator.ast_cache.length).to eq 3
      calculator.clear_cache
      expect(calculator.ast_cache.keys).to be_empty
    end

    it 'clears one item from cache' do
      calculator.clear_cache("1+1")
      expect(calculator.ast_cache.keys.sort).to eq([
        'pi * radius ^ 2',
        'pineapples * 5',
      ])
    end

    it 'clears items matching regex from cache' do
      calculator.clear_cache(/^pi/)
      expect(calculator.ast_cache.keys.sort).to eq(['1+1'])
    end
  end

  describe 'string functions' do
    it 'concatenates two strings' do
      expect(
        calculator.evaluate('CONCAT(s1, s2)', 's1' => 'abc', 's2' => 'def')
      ).to eq 'abcdef'
    end
  end
end
