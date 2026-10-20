require 'spec_helper'
require 'dentaku'
require 'dentaku/bulk_expression_solver'
require 'dentaku/calculator'
require 'dentaku/exceptions'

RSpec.describe Dentaku::BulkExpressionSolver do
  let(:calculator) { Dentaku::Calculator.new }

  describe "#solve!" do
    it 'does not reuse a cached order after formulas change with the same variable names' do
      calculator = Dentaku::Calculator.new(cache_dependency_order: true)
      calculator.store(seed: 1)
      expect(calculator.solve!(a: 'b + 1', b: 'seed + 1')).to eq(a: 3, b: 2)
      expect(calculator.solve!(a: 'seed + 1', b: 'a + 1')).to eq(a: 2, b: 3)
    end

    it 'does not share a cached order with a calculator using different dependencies' do
      first = Dentaku::Calculator.new(cache_dependency_order: true).store(seed: 1)
      second = Dentaku::Calculator.new(cache_dependency_order: true).store(seed: 10)
      expect(first.solve!(left: 'right + 1', right: 'seed + 1')).to eq(left: 3, right: 2)
      expect(second.solve!(left: 'seed + 1', right: 'left + 1')).to eq(left: 11, right: 12)
    end

    it 'includes memory-dependent edges in the cached order' do
      # the stored value decides where the cycle is broken, so each calculator
      # needs a different order for the same formulas
      first = Dentaku::Calculator.new(cache_dependency_order: true).store(x: 5)
      second = Dentaku::Calculator.new(cache_dependency_order: true).store(y: 3)
      formulas = { x: 'y + 3', y: 'x * 2' }
      expect(first.solve!(formulas)).to eq(x: 13, y: 10)
      expect(second.solve!(formulas)).to eq(x: 6, y: 12)
    end

    it "evaluates properly with variables, even if some in memory" do
      expressions = {
        weekly_fruit_budget: "weekly_apple_budget + pear * 4",
        weekly_apple_budget: "apples * 7",
        pear: "1"
      }
      solver = described_class.new(expressions, calculator.store(apples: 3))
      expect(solver.solve!)
        .to eq(pear: 1, weekly_apple_budget: 21, weekly_fruit_budget: 25)
    end

    it "lets you know if a variable is unbound" do
      expressions = {more_apples: "apples + 1"}
      expect {
        described_class.new(expressions, calculator).solve!
      }.to raise_error(Dentaku::UnboundVariableError)
    end

    it "properly handles access on an unbound variable" do
      expressions = {more_apples: "apples[0]"}
      expect {
        described_class.new(expressions, calculator).solve!
      }.to raise_error(Dentaku::UnboundVariableError)
    end

    it "lets you know if the result is a div/0 error when dividing" do
      expressions = {more_apples: "1/0"}
      expect {
        described_class.new(expressions, calculator).solve!
      }.to raise_error(Dentaku::ZeroDivisionError)
    end

    it "lets you know if the result is a div/0 error when taking modulo" do
      expressions = {more_apples: "1%0"}
      expect {
        described_class.new(expressions, calculator).solve!
      }.to raise_error(Dentaku::ZeroDivisionError)
    end

    it "does not require keys to be parseable" do
      expressions = { "the value of x, incremented" => "x + 1" }
      solver = described_class.new(expressions, calculator.store("x" => 3))
      expect(solver.solve!).to eq("the value of x, incremented" => 4)
    end

    it "allows self-referential formulas" do
      expressions = { x: "x + 1" }
      solver = described_class.new(expressions, calculator.store(x: 1))
      expect(solver.solve!).to eq(x: 2)

      expressions = { x: "y + 3", y: "x * 2" }
      solver = described_class.new(expressions, calculator.store(x: 5, y: 3))
      expect(solver.solve!).to eq(x: 6, y: 12) # x = 6 by the time y is calculated
    end

    describe "when a key being solved is also stored in memory" do
      it "gives formulas the solved value regardless of key order" do
        calculator.store(discount: 20, foo: 20)
        expected = { discount: 50, discount_not_applicable: true }

        expect(calculator.solve!(
          discount: "foo + 30",
          discount_not_applicable: "IF(discount > 30, true, false)"
        )).to eq(expected)

        expect(calculator.solve!(
          discount_not_applicable: "IF(discount > 30, true, false)",
          discount: "foo + 30"
        )).to eq(expected)
      end

      it "follows the solved value through a chain of formulas" do
        calculator.store(seed: 1, middle: 100)
        expect(calculator.solve!(
          top: "middle * 2",
          middle: "bottom + 1",
          bottom: "seed + 1"
        )).to eq(top: 6, middle: 3, bottom: 2)
      end

      it "still uses the stored value to break a cycle elsewhere in the system" do
        calculator.store(x: 5, y: 3, d: 20, foo: 1)
        expect(calculator.solve!(
          z: "d + 1",
          x: "y + 3",
          y: "x * 2",
          d: "foo + 1"
        )).to eq(z: 3, x: 6, y: 12, d: 2)
      end

      it "does not change the reported dependencies" do
        calculator.store(discount: 20, foo: 20)
        solver = described_class.new(
          { discount_not_applicable: "IF(discount > 30, true, false)", discount: "foo + 30" },
          calculator
        )
        expect(solver.dependencies).to eq("discount_not_applicable" => [], "discount" => [])
      end
    end

    it "does not execute functions unnecessarily" do
      calls = 0
      external = ->() { calls += 1 }
      hash = {test: 'EXTERNAL()'}
      calculator = Dentaku::Calculator.new
      calculator.add_function(:external, :numeric, external)
      calculator.solve(hash)
      expect(calls).to eq(1)
    end

    it "evaluates expressions in hashes and arrays, and expands the results" do
      calculator.store(
        fruit_quantities: {
          apple: 5,
          pear: 9
        },
        fruit_prices: {
          apple: 1.66,
          pear: 2.50
        }
      )
      expressions = {
        weekly_budget: {
          fruit:  "weekly_budget.apples + weekly_budget.pears",
          apples: "fruit_quantities.apple * discounted_fruit_prices.apple",
          pears:  "fruit_quantities.pear * discounted_fruit_prices.pear",
        },
        discounted_fruit_prices: {
          apple: "round(fruit_prices.apple * discounts[0], 2)",
          pear: "round(fruit_prices.pear * discounts[1], 2)"
        },
        discounts: ["0.4 * 2", "0.3 * 2"],
      }
      solver = described_class.new(expressions, calculator)

      expect(solver.solve!).to eq(
        weekly_budget: {
          fruit: 20.15,
          apples: 6.65,
          pears: 13.50
        },
        discounted_fruit_prices: {
          apple: 1.33,
          pear: 1.50
        },
        discounts: [0.8, 0.6]
      )
    end

    it "solves arrays of hashes" do
      calculator.store(bonus: 5)
      expressions = {
        percents: [{ percent: 75 }, { percent: "30 + bonus" }],
        average: "(percents[0].percent + percents[1].percent) / 2",
      }

      expect(calculator.solve!(expressions)).to eq(
        percents: [{ percent: 75 }, { percent: 35 }],
        average: 55
      )
    end

    it "solves nested arrays" do
      expect(calculator.solve!(grid: [[1, "1 + 1"], [{ cell: "1 + 2" }]])).to eq(
        grid: [[1, 2], [{ cell: 3 }]]
      )
    end
  end

  describe "#solve" do
    it 'resolves capitalized keys when they are declared out of order' do
      expressions = {
        FIRST: "SECOND * 2",
        SECOND: "THIRD * 2",
        THIRD: 2,
      }

      result = described_class.new(expressions, calculator).solve

      expect(result).to eq(
        FIRST: 8,
        SECOND: 4,
        THIRD: 2
      )
    end

    it 'resolves mixed-case keys declared out of order when case-sensitive' do
      calculator = Dentaku::Calculator.new(case_sensitive: true)
      expressions = {
        'TopLevel'    => 'MidLevel * 2',
        'MidLevel'    => 'BottomLevel * 2',
        'BottomLevel' => '2'
      }

      result = described_class.new(expressions, calculator).solve

      expect(result).to eq(
        'TopLevel'    => 8,
        'MidLevel'    => 4,
        'BottomLevel' => 2
      )
    end

    it 'does not expose a downcased alias of a constant when case-sensitive' do
      calculator = Dentaku::Calculator.new(case_sensitive: true)
      expressions = { 'BottomLevel' => '2', 'TopLevel' => 'bottomlevel * 2' }

      expect {
        described_class.new(expressions, calculator).solve!
      }.to raise_error(Dentaku::UnboundVariableError, /bottomlevel/)
    end

    it 'falls back to mixed-case memory values when case-sensitive' do
      calculator = Dentaku::Calculator.new(case_sensitive: true)
      calculator.store('MyVar' => 7)

      result = described_class.new({ 'MyVar' => 'Missing + 1' }, calculator).solve

      expect(result).to eq('MyVar' => 7)
    end

    it "returns :undefined when variables are unbound" do
      expressions = {more_apples: "apples + 1"}
      expect(described_class.new(expressions, calculator).solve)
        .to eq(more_apples: :undefined)
    end

    it "allows passing in a custom value to an error handler when a variable is unbound" do
      expressions = {more_apples: "apples + 1"}
      expect(described_class.new(expressions, calculator).solve { :foo })
        .to eq(more_apples: :foo)
    end

    it "allows passing in a custom value to an error handler when there is a div/0 error" do
      expressions = {more_apples: "1/0"}
      expect(described_class.new(expressions, calculator).solve { :foo })
        .to eq(more_apples: :foo)
    end

    it "allows passing in ast as expression" do
      expressions = {more_apples: calculator.ast("1/0")}
      expect(described_class.new(expressions, calculator).solve { :foo })
        .to eq(more_apples: :foo)
    end

    it 'stores the recipient variable on the exception when there is a div/0 error' do
      expressions = {more_apples: "1/0"}
      exception = nil
      described_class.new(expressions, calculator).solve do |ex|
        exception = ex
      end
      expect(exception.assigned_to).to eq('more_apples')
    end

    it 'stores the recipient variable on the exception when there is an unbound variable' do
      expressions = {more_apples: "apples + 1"}
      exception = nil
      described_class.new(expressions, calculator).solve do |ex|
        exception = ex
      end
      expect(exception.assigned_to).to eq('more_apples')
    end

    it 'sets the recipient variable before the solve block is invoked' do
      expressions = {more_apples: "apples + 1"}
      seen = :unset
      described_class.new(expressions, calculator).solve do |ex|
        seen = ex.assigned_to
        :err
      end
      expect(seen).to eq('more_apples')
    end

    it 'stores the recipient variable on the exception when there is an ArgumentError' do
      expressions = {apples: "NULL", more_apples: "1 + apples"}
      exception = nil
      described_class.new(expressions, calculator).solve do |ex|
        exception = ex
      end
      expect(exception.assigned_to).to eq('more_apples')
    end

    it 'safely handles argument errors' do
      expressions = {i: "a / 5 + d", a: "m * 12", d: "a + b"}
      result = described_class.new(expressions, calculator.store(m: 3)).solve
      expect(result).to eq(
        i: :undefined,
        d: :undefined,
        a: 36,
      )
    end

    it 'supports nested hashes of expressions using dot notation' do
      expressions = {
        a:  "25",
        b: {
          c: "a / 5",
          d: [3, 4, 5]
        },
        e: ["b.c + b.d[1]"],
        f: "e[0] + 1"
      }
      results = described_class.new(expressions, calculator).solve
      expect(results[:f]).to eq(10)
    end

    it 'uses stored values for expressions when they are known' do
      calculator.store(Force: 50, Mass: 25)
      expressions = {
        Force: "Mass * Acceleration",
        Mass: "Force / Acceleration",
        Acceleration: "Force / Mass",
      }
      solver = described_class.new(expressions, calculator)
      results = solver.solve
      expect(results).to eq(Force: 50, Mass: 25, Acceleration: 2)
    end

    it 'solves all array expressions for which context exists, returning :undefined for the rest' do
      calculator.store(first: 1, equation: 3)
      system = {'key' => ['first * equation', 'second * equation'] }
      solver = described_class.new(system, calculator)
      expect(solver.dependencies).to eq('key' => ['second'])
      results = solver.solve
      expect(results).to eq('key' => [3, :undefined])
      expect { solver.solve! }.to raise_error(Dentaku::UnboundVariableError)
    end

    it do
      calculator.store(val: nil)
      expressions = {
        a: 'IF(5 / 0 > 0, 100, 1000)',
        b: 'IF(val = 0, 0, IF(val > 0, 0, 0))'
      }
      solver = described_class.new(expressions, calculator)
      results = solver.solve
      expect(results).to eq(a: :undefined, b: :undefined)
    end
  end
end
