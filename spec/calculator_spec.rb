require 'spec_helper'
require 'dentaku'
describe Dentaku::Calculator do
  let(:calculator)   { described_class.new }
  let(:with_case_sensitivity) { described_class.new(case_sensitive: true) }
  let(:with_memory)  { described_class.new.store(apples: 3) }
  let(:with_aliases) { described_class.new(aliases: { round: ['rrround'] }) }
  let(:without_nested_data) { described_class.new(nested_data_support: false) }

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
    expect(calculator.evaluate('1353+91-1-3322-22')).to eq(-1901)
    expect(calculator.evaluate('1 + -(2 ^ 2)')).to eq(-3)
    expect(calculator.evaluate('3 + -num', num: 2)).to eq(1)
    expect(calculator.evaluate('-num + 3', num: 2)).to eq(1)
    expect(calculator.evaluate('10 ^ 2')).to eq(100)
    expect(calculator.evaluate('0 * 10 ^ -5')).to eq(0)
    expect(calculator.evaluate('3 + 0 * -3')).to eq(3)
    expect(calculator.evaluate('3 + 0 / -3')).to eq(3)
    expect(calculator.evaluate('(((695759/735000)^(1/(1981-1991)))-1)*1000').round(4)).to eq(5.5018)
    expect(calculator.evaluate('0.253/0.253')).to eq(1)
    expect(calculator.evaluate('0.253/d', d: 0.253)).to eq(1)
    expect(calculator.evaluate('10 + x', x: 'abc')).to be_nil
    expect(calculator.evaluate('x * y', x: '.123', y: '100')).to eq(12.3)
    expect(calculator.evaluate('a/b', a: '10', b: '2')).to eq(5)
    expect(calculator.evaluate('t + 1*24*60*60', t: Time.local(2017, 1, 1))).to eq(Time.local(2017, 1, 2))
    expect(calculator.evaluate("2 | 3 * 9")).to eq (27)
    expect(calculator.evaluate("2 & 3 * 9")).to eq (2)
    expect(calculator.evaluate('1 << 3')).to eq (8)
    expect(calculator.evaluate('0xFF >> 6')).to eq (3)
  end

  it "differentiates between percentage and modulo operators" do
    expect(calculator.evaluate('15 % 8')).to eq(7)
    expect(calculator.evaluate('15 % (4 * 2)')).to eq(7)
    expect(calculator.evaluate("5%")).to eq (0.05)
    expect(calculator.evaluate("400/60%").round(2)).to eq (666.67)
    expect(calculator.evaluate("(400/60%)*1").round(2)).to eq (666.67)
    expect(calculator.evaluate("60% * 1").round(2)).to eq (0.60)
    expect(calculator.evaluate("50% + 50%")).to eq (1.0)
  end

  describe 'evaluate' do
    it 'returns nil when formula has error' do
      expect(calculator.evaluate('1 + + 1')).to be_nil
    end

    it 'suppresses unbound variable errors' do
      expect(calculator.evaluate('AND(a,b)')).to be_nil
      expect(calculator.evaluate('IF(a, 1, 0)')).to be_nil
      expect(calculator.evaluate('MAX(a,b)')).to be_nil
      expect(calculator.evaluate('MIN(a,b)')).to be_nil
      expect(calculator.evaluate('NOT(a)')).to be_nil
      expect(calculator.evaluate('OR(a,b)')).to be_nil
      expect(calculator.evaluate('ROUND(a)')).to be_nil
      expect(calculator.evaluate('ROUNDDOWN(a)')).to be_nil
      expect(calculator.evaluate('ROUNDUP(a)')).to be_nil
      expect(calculator.evaluate('SUM(a,b)')).to be_nil
    end

    it 'suppresses numeric coercion errors' do
      expect(calculator.evaluate('MAX(a,b)', a: nil, b: nil)).to be_nil
      expect(calculator.evaluate('MIN(a,b)', a: nil, b: nil)).to be_nil
      expect(calculator.evaluate('ROUND(a)', a: nil)).to be_nil
      expect(calculator.evaluate('ROUNDDOWN(a)', a: nil)).to be_nil
      expect(calculator.evaluate('ROUNDUP(a)', a: nil)).to be_nil
      expect(calculator.evaluate('SUM(a,b)', a: nil, b: nil)).to be_nil
      expect(calculator.evaluate('1.0 & "bar"')).to be_nil
    end

    it 'treats explicit nil as logical false' do
      expect(calculator.evaluate('AND(a,b)', a: nil, b: nil)).to be_falsy
      expect(calculator.evaluate('IF(a,1,0)', a: nil, b: nil)).to eq(0)
      expect(calculator.evaluate('NOT(a)', a: nil, b: nil)).to be_truthy
      expect(calculator.evaluate('OR(a,b)', a: nil, b: nil)).to be_falsy
    end

    it 'supports lazy evaluation of variables' do
      expect(calculator.evaluate('x + 1', x: -> { 1 })).to eq(2)
      expect { calculator.evaluate('2', x: -> { raise 'boom' }) }.not_to raise_error
    end
  end

  describe 'ast' do
    it 'raises parsing errors' do
      expect { calculator.ast('()') }.to raise_error(Dentaku::ParseError)
      expect { calculator.ast('(}') }.to raise_error(Dentaku::TokenizerError)
    end
  end

  describe 'evaluate!' do
    it 'raises exception when formula has error' do
      expect { calculator.evaluate!('1 + + 1') }.to raise_error(Dentaku::ParseError)
      expect { calculator.evaluate!('(1 > 5) OR LEFT("abc", 1)') }.to raise_error(Dentaku::ParseError)
    end

    it 'raises unbound variable errors' do
      expect { calculator.evaluate!('AND(a,b)') }.to raise_error(Dentaku::UnboundVariableError)
      expect { calculator.evaluate!('IF(a, 1, 0)') }.to raise_error(Dentaku::UnboundVariableError)
      expect { calculator.evaluate!('MAX(a,b)') }.to raise_error(Dentaku::UnboundVariableError)
      expect { calculator.evaluate!('MIN(a,b)') }.to raise_error(Dentaku::UnboundVariableError)
      expect { calculator.evaluate!('NOT(a)') }.to raise_error(Dentaku::UnboundVariableError)
      expect { calculator.evaluate!('OR(a,b)') }.to raise_error(Dentaku::UnboundVariableError)
      expect { calculator.evaluate!('ROUND(a)') }.to raise_error(Dentaku::UnboundVariableError)
      expect { calculator.evaluate!('ROUNDDOWN(a)') }.to raise_error(Dentaku::UnboundVariableError)
      expect { calculator.evaluate!('ROUNDUP(a)') }.to raise_error(Dentaku::UnboundVariableError)
      expect { calculator.evaluate!('SUM(a,b)') }.to raise_error(Dentaku::UnboundVariableError)
    end

    it 'raises numeric coersion errors' do
      expect { calculator.evaluate!('MAX(a,b)', a: nil, b: nil) }.to raise_error(Dentaku::ArgumentError)
      expect { calculator.evaluate!('MIN(a,b)', a: nil, b: nil) }.to raise_error(Dentaku::ArgumentError)
      expect { calculator.evaluate!('ROUND(a)', a: nil) }.to raise_error(Dentaku::ArgumentError)
      expect { calculator.evaluate!('ROUNDDOWN(a)', a: nil) }.to raise_error(Dentaku::ArgumentError)
      expect { calculator.evaluate!('ROUNDUP(a)', a: nil) }.to raise_error(Dentaku::ArgumentError)
      expect { calculator.evaluate!('SUM(a,b)', a: nil, b: nil) }.to raise_error(Dentaku::ArgumentError)
      expect { calculator.evaluate!('"foo" & "bar"') }.to raise_error(Dentaku::ArgumentError)
      expect { calculator.evaluate!('1.0 & "bar"') }.to raise_error(Dentaku::ArgumentError)
      expect { calculator.evaluate!('1 & "bar"') }.to raise_error(Dentaku::ArgumentError)
    end

    it 'raises argument error if a function is called with incorrect arity' do
      expect { calculator.evaluate!('IF(a,b)', a: 1, b: 1) }.to raise_error(Dentaku::ParseError)
    end
  end

  it 'supports unicode characters in identifiers' do
    expect(calculator.evaluate("ρ * 2", ρ: 2)).to eq (4)
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
      expect(calculator.evaluate!('i_am_false')).to eq(false)
    end

    it 'can store multiple values' do
      calculator.store(first: 1, second: 2)
      expect(calculator.evaluate!('first')).to eq(1)
      expect(calculator.evaluate!('second')).to eq(2)
    end

    it 'stores formulas' do
      calculator.store_formula('area', 'length * width')
      expect(calculator.evaluate!('area', length: 5, width: 5)).to eq(25)
    end

    it 'stores dates' do
      calculator.store("d1", Date.parse("2024/01/02"))
      calculator.store("d2", Date.parse("2024/01/06"))
      expect(calculator.solve(diff: "d1 - d2")).to eq(diff: -4)
    end

    it 'stores nested hashes' do
      calculator.store(a: {basket: {of: 'apples'}}, b: 2)
      expect(calculator.evaluate!('a.basket.of')).to eq('apples')
      expect(calculator.evaluate!('a.basket')).to eq(of: 'apples')
      expect(calculator.evaluate!('b')).to eq(2)
    end

    it 'stores nested hashes with quotes' do
      calculator.store(a: {basket: {of: 'apples'}}, b: 2)
      expect(calculator.evaluate!('`a.basket.of`')).to eq('apples')
      expect(calculator.evaluate!('`a.basket`')).to eq(of: 'apples')
      expect(calculator.evaluate!('`b`')).to eq(2)
    end

    it 'stores arrays' do
      calculator.store(a: [1, 2, 3])
      expect(calculator.evaluate!('a[0]')).to eq(1)
      expect(calculator.evaluate!('a[x]', x: 1)).to eq(2)
      expect(calculator.evaluate!('a[x+1]', x: 1)).to eq(3)
    end

    it 'evaluates arrays' do
      expect(calculator.evaluate([1, 2, 3])).to eq([1, 2, 3])
      expect(calculator.evaluate!('{1,2,3}')).to eq([1, 2, 3])
    end
  end

  describe 'dependencies' do
    it 'respects quoted identifiers in dependencies' do
      expect(calculator.dependencies("`bob the builder` + `dole the digger` / 3")).to eq(['bob the builder', 'dole the digger'])
    end

    it "finds dependencies in a generic statement" do
      expect(calculator.dependencies("bob + dole / 3")).to eq(['bob', 'dole'])
    end

    it "ignores dependencies passed in context" do
      expect(calculator.dependencies("a + b", a: 1)).to eq(['b'])
    end

    it "ignores dependencies passed in context for quoted identifiers" do
      expect(calculator.dependencies("`a-c` + b", "a-c": 1)).to eq(['b'])
    end

    it "finds dependencies in formula arguments" do
      allow(Dentaku).to receive(:cache_ast?) { true }

      expect(calculator.dependencies("CONCAT(bob, dole)")).to eq(['bob', 'dole'])
    end

    it "doesn't consider variables in memory as dependencies" do
      expect(with_memory.dependencies("apples + oranges")).to eq(['oranges'])
    end

    it "finds no dependencies in array literals" do
      expect(calculator.dependencies([1, 2, 3])).to eq([])
    end

    it "finds dependencies in item expressions" do
      expect(calculator.dependencies('MAP(vals, val, val + step)')).to eq(['vals', 'step'])
      expect(calculator.dependencies('ALL(people, person, person.age < adult)')).to eq(['people', 'adult'])
    end
  end

  describe 'solve!' do
    it "evaluates properly with variables, even if some in memory" do
      expect(with_memory.solve!(
        "monthly fruit budget": "weekly_fruit_budget * 4",
        weekly_fruit_budget: "weekly_apple_budget + pear * 4",
        weekly_apple_budget: "apples * 7",
        pear:                "1"
      )).to eq(pear: 1, weekly_apple_budget: 21, weekly_fruit_budget: 25, "monthly fruit budget": 100)
    end

    it "prefers variables over values in memory if they have no dependencies" do
      expect(with_memory.solve!(
        weekly_fruit_budget: "weekly_apple_budget + pear * 4",
        weekly_apple_budget: "apples * 7",
        pear:                "1",
        apples:              "4"
      )).to eq(apples: 4, pear: 1, weekly_apple_budget: 28, weekly_fruit_budget: 32)
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
      expect(result[:total_fruit]).to eq(13)
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

      expect(result[:weight]).to eq(130.368)
    end

    it 'raises an exception if there are cyclic dependencies' do
      expect {
        calculator.solve!(
          make_money: "have_money",
          have_money: "make_money"
        )
      }.to raise_error(TSort::Cyclic)
    end
  end

  describe 'solve' do
    it "returns :undefined when variables are unbound" do
      expressions = {more_apples: "apples + 1", compare_apples: "apples > 1"}
      expect(calculator.solve(expressions)).to eq(more_apples: :undefined, compare_apples: :undefined)
    end

    it "returns :undefined when variables are nil" do
      expressions = {more_apples: "apples + 1", compare_apples: "apples > 1"}
      expect(calculator.store(apples: nil).solve(expressions)).to eq(more_apples: :undefined, compare_apples: :undefined)
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

    it 'returns undefined if there are cyclic dependencies' do
      expect {
        result = calculator.solve(
          make_money: "have_money",
          have_money: "make_money"
        )
        expect(result).to eq(
          make_money: :undefined,
          have_money: :undefined
        )
      }.not_to raise_error
    end

    it 'allows to compare "-" or "-."' do
      expect { calculator.solve("IF('-' =  '-', 0, 1)") }.not_to raise_error
      expect { calculator.solve("IF('-.'= '-.', 0, 1)") }.not_to raise_error
    end

    it "integrates with custom functions" do
      calculator.add_function(:custom, :integer, -> { 1 })

      result = calculator.solve(
        a: "1",
        b: "CUSTOM() - a"
      )

      expect(result).to eq(
        a: 1,
        b: 0
      )
    end
  end

  it 'evaluates a statement with no variables' do
    expect(calculator.evaluate('5+3')).to eq(8)
    expect(calculator.evaluate('(1+1+1)/3*100')).to eq(100)
  end

  it 'evaluates negation' do
    expect(calculator.evaluate('-negative', negative: -1)).to eq(1)
    expect(calculator.evaluate('-negative', negative: '-1')).to eq(1)
    expect(calculator.evaluate('-negative - 1', negative: '-1')).to eq(0)
    expect(calculator.evaluate('-negative - 1', negative: '1')).to eq(-2)
    expect(calculator.evaluate('-(negative) - 1', negative: '1')).to eq(-2)
  end

  it 'fails to evaluate unbound statements' do
    unbound = 'foo * 1.5'
    expect { calculator.evaluate!(unbound) }.to raise_error(Dentaku::UnboundVariableError)
    expect { calculator.evaluate!(unbound) }.to raise_error do |error|
      expect(error.unbound_variables).to eq(['foo'])
    end
    expect { calculator.evaluate!('a + b') }.to raise_error do |error|
      expect(error.unbound_variables).to eq(['a', 'b'])
    end
    expect(calculator.evaluate(unbound)).to be_nil
  end

  it 'accepts a block for custom handling of unbound variables' do
    unbound = 'foo * 1.5'
    expect(calculator.evaluate(unbound) { :bar }).to eq(:bar)
    expect(calculator.evaluate(unbound) { |e| e }).to eq(unbound)
  end

  it 'fails to evaluate incomplete statements' do
    ['true AND', 'a a ^&'].each do |statement|
      expect {
        calculator.evaluate!(statement)
      }.to raise_error(Dentaku::ParseError)
    end
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

  it 'accepts special characters in quoted identifiers' do
    expect(calculator.evaluate('`foo1 bar` * 2', "foo1 bar": 2)).to eq(4)
    expect(calculator.evaluate('`foo1-bar` * 2', 'foo1-bar' => 4)).to eq(8)
    expect(calculator.evaluate('`1foo (bar)` * 2', '1foo (bar)' => 2)).to eq(4)
    expect(calculator.evaluate('`fo1o *bar*` * 2', 'fo1o *bar*': 4)).to eq(8)
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

  it 'compares time variables' do
    expect(calculator.evaluate('t1 < t2', t1: Time.local(2017, 1, 1).to_datetime, t2: Time.local(2017, 1, 2).to_datetime)).to be_truthy
    expect(calculator.evaluate('t1 < t2', t1: Time.local(2017, 1, 2).to_datetime, t2: Time.local(2017, 1, 1).to_datetime)).to be_falsy
    expect(calculator.evaluate('t1 > t2', t1: Time.local(2017, 1, 1).to_datetime, t2: Time.local(2017, 1, 2).to_datetime)).to be_falsy
    expect(calculator.evaluate('t1 > t2', t1: Time.local(2017, 1, 2).to_datetime, t2: Time.local(2017, 1, 1).to_datetime)).to be_truthy
  end

  it 'compares time literals with time variables' do
    expect(calculator.evaluate('t1 < 2017-01-02', t1: Time.local(2017, 1, 1).to_datetime)).to be_truthy
    expect(calculator.evaluate('t1 < 2017-01-02', t1: Time.local(2017, 1, 3).to_datetime)).to be_falsy
    expect(calculator.evaluate('t1 > 2017-01-02', t1: Time.local(2017, 1, 1).to_datetime)).to be_falsy
    expect(calculator.evaluate('t1 > 2017-01-02', t1: Time.local(2017, 1, 3).to_datetime)).to be_truthy
  end

  describe 'disabling date literals' do
    it 'does not parse formulas with minus signs as dates' do
      calculator = described_class.new(raw_date_literals: false)
      expect(calculator.evaluate!('2020-01-01')).to eq(2018)
    end
  end

  describe 'supports date arithmetic' do
    it 'from hardcoded string' do
      expect(calculator.evaluate!('2020-01-01 + 30').to_date).to eq(Time.local(2020, 1, 31).to_date)
      expect(calculator.evaluate!('2020-01-01 - 1').to_date).to eq(Time.local(2019, 12, 31).to_date)
      expect(calculator.evaluate!('2020-01-01 - 2019-12-31')).to eq(1)
      expect(calculator.evaluate!('2020-01-01 + duration(1, day)').to_date).to eq(Time.local(2020, 1, 2).to_date)
      expect(calculator.evaluate!('2020-01-01 - duration(1, day)').to_date).to eq(Time.local(2019, 12, 31).to_date)
      expect(calculator.evaluate!('2020-01-01 + duration(30, days)').to_date).to eq(Time.local(2020, 1, 31).to_date)
      expect(calculator.evaluate!('2020-01-01 + duration(1, month)').to_date).to eq(Time.local(2020, 2, 1).to_date)
      expect(calculator.evaluate!('2020-01-01 - duration(1, month)').to_date).to eq(Time.local(2019, 12, 1).to_date)
      expect(calculator.evaluate!('2020-01-01 + duration(30, months)').to_date).to eq(Time.local(2022, 7, 1).to_date)
      expect(calculator.evaluate!('2020-01-01 + duration(1, year)').to_date).to eq(Time.local(2021, 1, 1).to_date)
      expect(calculator.evaluate!('2020-01-01 - duration(1, year)').to_date).to eq(Time.local(2019, 1, 1).to_date)
      expect(calculator.evaluate!('2020-01-01 + duration(30, years)').to_date).to eq(Time.local(2050, 1, 1).to_date)
    end

    it 'from string variable' do
      value = '2023-01-01'
      value2 = '2022-12-31'

      expect(calculator.evaluate!('value + duration(1, month)', { value: value }).to_date).to eq(Date.parse('2023-02-01'))
      expect(calculator.evaluate!('value - duration(1, month)', { value: value }).to_date).to eq(Date.parse('2022-12-01'))
      expect(calculator.evaluate!('value - value2', { value: value, value2: value2 })).to eq(1)
    end

    it 'from date object' do
      value = Date.parse('2023-01-01').to_date
      value2 = Date.parse('2022-12-31').to_date

      expect(calculator.evaluate!('value + duration(1, month)', { value: value }).to_date).to eq(Date.parse('2023-02-01'))
      expect(calculator.evaluate!('value - duration(1, month)', { value: value }).to_date).to eq(Date.parse('2022-12-01'))
      expect(calculator.evaluate!('value - value2', { value: value, value2: value2 })).to eq(1)
    end

    it 'from time object' do
      value = Time.local(2023, 7, 13, 10, 42, 11)
      value2 = Time.local(2023, 12, 1, 9, 42, 10)

      expect(calculator.evaluate!('value + duration(1, month)', { value: value })).to eq(Time.local(2023, 8, 13, 10, 42, 11))
      expect(calculator.evaluate!('value - duration(1, day)', { value: value })).to eq(Time.local(2023, 7, 12, 10, 42, 11))
      expect(calculator.evaluate!('value - duration(1, year)', { value: value })).to eq(Time.local(2022, 7, 13, 10, 42, 11))
      expect(calculator.evaluate!('value2 - value', { value: value, value2: value2 })).to eq(12_182_399.0)
      expect(calculator.evaluate!('value - 7200', { value: value })).to eq(Time.local(2023, 7, 13, 8, 42, 11))
    end
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
      expect(calculator.evaluate('round(8.75, 1)')).to eq(BigDecimal('8.8'))

      expect(calculator.evaluate('ROUND(apples * 0.93)', apples: 10)).to eq(9)
    end

    it 'include ABS' do
      expect(calculator.evaluate('abs(-2.2)')).to eq(2.2)
      expect(calculator.evaluate('abs(5)')).to eq(5)

      expect(calculator.evaluate('ABS(x * -1)', x: 10)).to eq(10)
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
      expect(calculator.evaluate('round(-1.23, 1)')).to eq(BigDecimal('-1.2'))
      expect(calculator.evaluate('NOT(some_boolean) AND -1 > 3', some_boolean: true)).to be_falsey
    end

    it 'calculates intercept correctly' do
      x_values = [1, 2, 3, 4, 5]
      y_values = [2, 3, 5, 4, 6]
      result = calculator.evaluate('INTERCEPT(x_values, y_values)', x_values: x_values, y_values: y_values)
      expect(result).to be_within(0.001).of(1.3)
    end

    describe "any" do
      it "enumerates values and returns true if any evaluation is truthy" do
        expect(calculator.evaluate!('any(xs, x, x > 3)', xs: [1, 2, 3, 4])).to be_truthy
        expect(calculator.evaluate!('any(xs, x, x > 3)', xs: 3)).to be_falsy
        expect(calculator.evaluate!('any({1,2,3,4}, x, x > 3)')).to be_truthy
        expect(calculator.evaluate!('any({1,2,3,4}, x, x > 10)')).to be_falsy
        expect(calculator.evaluate!('any(users, u, u.age > 33)', users: [
          {name: "Bob",  age: 44},
          {name: "Jane", age: 27}
        ])).to be_truthy
        expect(calculator.evaluate!('any(users, u, u.age < 18)', users: [
          {name: "Bob",  age: 44},
          {name: "Jane", age: 27}
        ])).to be_falsy
      end
    end

    describe "all" do
      it "enumerates values and returns true if all evaluations are truthy" do
        expect(calculator.evaluate!('all(xs, x, x > 3)', xs: [1, 2, 3, 4])).to be_falsy
        expect(calculator.evaluate!('any(xs, x, x > 2)', xs: 3)).to be_truthy
        expect(calculator.evaluate!('all({1,2,3,4}, x, x > 0)')).to be_truthy
        expect(calculator.evaluate!('all({1,2,3,4}, x, x > 10)')).to be_falsy
        expect(calculator.evaluate!('all(users, u, u.age > 33)', users: [
          {name: "Bob",  age: 44},
          {name: "Jane", age: 27}
        ])).to be_falsy
        expect(calculator.evaluate!('all(users, u, u.age < 50)', users: [
          {name: "Bob",  age: 44},
          {name: "Jane", age: 27}
        ])).to be_truthy
      end
    end

    describe "map" do
      it "maps values" do
        expect(calculator.evaluate!('map(xs, x, x * 2)', xs: [1, 2, 3, 4])).to eq([2, 4, 6, 8])
        expect(calculator.evaluate!('map({1,2,3,4}, x, x * 2)')).to eq([2, 4, 6, 8])
        expect(calculator.evaluate!('map(users, u, u.age)', users: [
          {name: "Bob",  age: 44},
          {name: "Jane", age: 27}
        ])).to eq([44, 27])
        expect(calculator.evaluate!('map(users, u, u.age)', users: [
          {"name" => "Bob",  "age" => 44},
          {"name" => "Jane", "age" => 27}
        ])).to eq([44, 27])
        expect(calculator.evaluate!('map(users, u, u.name)', users: [
          {name: "Bob",  age: 44},
          {name: "Jane", age: 27}
        ])).to eq(["Bob", "Jane"])
        expect(calculator.evaluate!('map(users, u, u.name)', users: [
          {"name" => "Bob",  "age" => 44},
          {"name" => "Jane", "age" => 27}
        ])).to eq(["Bob", "Jane"])
        expect(calculator.evaluate!('map(users, u, IF(u.age < 30, u, null))', users: [
          {"name" => "Bob",  "age" => 44},
          {"name" => "Jane", "age" => 27}
        ])).to eq([nil, { "name" => "Jane", "age" => 27 }])
      end
    end

    describe "pluck" do
      it "plucks values from array of hashes" do
        expect(calculator.evaluate!('pluck(users, age)', users: [
          {name: "Bob",  age: 44},
          {name: "Jane", age: 27}
        ])).to eq([44, 27])
        expect(calculator.evaluate!('pluck(users, age)', users: [
          {"name" => "Bob",  "age" => 44},
          {"name" => "Jane", "age" => 27}
        ])).to eq([44, 27])
        expect(calculator.evaluate!('pluck(users, name)', users: [
          {name: "Bob",  age: 44},
          {name: "Jane", age: 27}
        ])).to eq(["Bob", "Jane"])
        expect(calculator.evaluate!('pluck(users, name)', users: [
          {"name" => "Bob",  "age" => 44},
          {"name" => "Jane", "age" => 27}
        ])).to eq(["Bob", "Jane"])
      end
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

  describe 'nil values' do
    it 'can be used explicitly' do
      expect(calculator.evaluate('IF(null, 1, 2)')).to eq(2)
    end

    it 'can be assigned to a variable' do
      expect(calculator.evaluate('IF(foo, 1, 2)', foo: nil)).to eq(2)
    end

    it 'are carried across middle terms' do
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

    it 'raise errors when used in arithmetic operations' do
      expect {
        calculator.solve!(more_apples: "apples + 1", apples: nil)
      }.to raise_error(Dentaku::ArgumentError)
    end
  end

  describe 'case statements' do
    let(:formula) {
      <<-FORMULA
      CASE fruit
      WHEN 'apple'
        THEN 1 * quantity
      WHEN 'banana'
        THEN 2 * quantity
      ELSE
        3 * quantity
      END
      FORMULA
    }

    it 'handles complex then statements' do
      expect(calculator.evaluate(formula, quantity: 3, fruit: 'apple')).to eq(3)
      expect(calculator.evaluate(formula, quantity: 3, fruit: 'banana')).to eq(6)
    end

    it 'evaluates case statement as part of a larger expression' do
      expect(calculator.evaluate("2 + #{formula}", quantity: 3, fruit: 'apple')).to eq(5)
      expect(calculator.evaluate("2 + #{formula}", quantity: 3, fruit: 'banana')).to eq(8)
      expect(calculator.evaluate("2 + #{formula}", quantity: 3, fruit: 'kiwi')).to eq(11)
      expect(calculator.evaluate("#{formula} + 2", quantity: 3, fruit: 'apple')).to eq(5)
      expect(calculator.evaluate("#{formula} + 2", quantity: 3, fruit: 'banana')).to eq(8)
      expect(calculator.evaluate("#{formula} + 2", quantity: 3, fruit: 'kiwi')).to eq(11)
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

    it 'raises an exception when no match and there is no default value' do
      formula = <<-FORMULA
      CASE number
      WHEN 42
        THEN 1
      END
      FORMULA
      expect { calculator.evaluate!(formula, number: 2) }
        .to raise_error("No block matched the switch value '2'")
    end

    it 'handles a default else statement' do
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

    it 'handles nested case statements with case-sensitivity' do
      formula = <<-FORMULA
      CASE fruit
      WHEN 'apple'
        THEN 1 * quantity
      WHEN 'banana'
        THEN
        CASE QUANTITY
        WHEN 1 THEN 2
        WHEN 10 THEN
          CASE type
          WHEN 'organic' THEN 5
          END
        END
      END
      FORMULA
      value = with_case_sensitivity.evaluate(
        formula,
        type: 'organic',
        quantity: 1,
        QUANTITY: 10,
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

  describe 'math support' do
    Math.methods(false).each do |method|
      it "includes `#{method}`" do
        if Math.method(method).arity == 2
          expect(calculator.evaluate("#{method}(x,y)", x: 1, y: '2')).to eq(Math.send(method, 1, 2))
          expect(calculator.evaluate("#{method}(x,y) + 1", x: 1, y: '2')).to be_within(0.00001).of(Math.send(method, 1, 2) + 1)
          expect { calculator.evaluate!("#{method}(x)", x: 1) }.to raise_error(Dentaku::ParseError)
        else
          expect(calculator.evaluate("#{method}(1)")).to eq(Math.send(method, 1))
          unless [:atanh, :frexp, :lgamma].include?(method)
            expect(calculator.evaluate("#{method}(1) + 1")).to be_within(0.00001).of(Math.send(method, 1) + 1)
          end
        end
      end
    end

    it 'defines a properly named class to support AST marshaling' do
      expect {
        Marshal.dump(calculator.ast('SQRT(20)'))
      }.not_to raise_error
    end

    it 'properly handles a Math::DomainError' do
      expect(calculator.evaluate('asin(2)')).to be_nil
      expect { calculator.evaluate!('asin(2)') }.to raise_error(Dentaku::MathDomainError)
    end
  end

  describe 'disable_cache' do
    before do
      allow(Dentaku).to receive(:cache_ast?) { true }
    end

    it 'disables the AST cache' do
      expect(calculator.disable_cache { |c| c.cache_ast? }).to be false
    end

    it 'calculates normally' do
      expect(calculator.disable_cache { |c| c.evaluate("2 + 2") }).to eq(4)
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
      expect(calculator.ast_cache.length).to eq(3)
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
    it 'concatenates strings' do
      expect(
        calculator.evaluate('CONCAT(s1, s2, s3)', 's1' => 'ab', 's2' => 'cd', 's3' => 'ef')
      ).to eq('abcdef')
    end

    it 'manipulates string arguments' do
      expect(calculator.evaluate("left('ABCD', 2)")).to eq('AB')
      expect(calculator.evaluate("right('ABCD', 2)")).to eq('CD')
      expect(calculator.evaluate("mid('ABCD', 2, 2)")).to eq('BC')
      expect(calculator.evaluate("len('ABCD')")).to eq(4)
      expect(calculator.evaluate("find('BC', 'ABCD')")).to eq(2)
      expect(calculator.evaluate("substitute('ABCD', 'BC', 'XY')")).to eq('AXYD')
      expect(calculator.evaluate("contains('BC', 'ABCD')")).to be_truthy
    end
  end

  describe 'zero-arity functions' do
    it 'can be used in formulas' do
      calculator.add_function(:two, :numeric, -> { 2 })
      expect(calculator.evaluate("max(two(), 1)")).to eq(2)
      expect(calculator.evaluate("max(1, two())")).to eq(2)
    end
  end

  describe 'aliases' do
    it 'accepts aliases as instance option' do
      expect(with_aliases.evaluate('rrround(5.1)')).to eq(5)
    end
  end

  describe 'nested_data' do
    it 'default to nested data enabled' do
      expect(calculator.nested_data_support).to be_truthy
    end

    it 'allow opt out of nested data support' do
      expect(without_nested_data.nested_data_support).to be_falsy
    end

    it 'should allow optout of nested hash' do
      expect do
        without_nested_data.solve!('a.b.c')
      end.to raise_error(Dentaku::UnboundVariableError)
    end
  end

  describe 'identifier cache' do
    it 'reduces call count by caching results of resolved identifiers' do
      called = 0
      calculator.store_formula("A1", "B1+B1+B1")
      calculator.store_formula("B1", "C1+C1+C1+C1")
      calculator.store_formula("C1", "D1")
      calculator.store("D1", proc { called += 1; 1 })

      expect {
        Dentaku.enable_identifier_cache!
      }.to change {
        called = 0
        calculator.evaluate("A1")
        called
      }.from(12).to(1)
    end
  end
end
