require 'spec_helper'
require 'dentaku/bulk_expression_solver'

RSpec.describe Dentaku::BulkExpressionSolver do
  let(:calculator) { Dentaku::Calculator.new }

  describe "#solve!" do
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

    it "lets you know if the result is a div/0 error" do
      expressions = {more_apples: "1/0"}
      expect {
        described_class.new(expressions, calculator).solve!
      }.to raise_error(Dentaku::ZeroDivisionError)
    end

    it "does not require keys to be parseable" do
      expressions = { "the value of x, incremented" => "x + 1" }
      solver = described_class.new(expressions, calculator.store("x" => 3))
      expect(solver.solve!).to eq({ "the value of x, incremented" => 4 })
    end
  end

  describe "#solve" do
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

    it 'stores the recipient variable on the exception when there is a div/0 error' do
      expressions = {more_apples: "1/0"}
      exception = nil
      described_class.new(expressions, calculator).solve do |ex|
        exception = ex
      end
      expect(exception.recipient_variable).to eq('more_apples')
    end

    it 'stores the recipient variable on the exception when there is an unbound variable' do
      expressions = {more_apples: "apples + 1"}
      exception = nil
      described_class.new(expressions, calculator).solve do |ex|
        exception = ex
      end
      expect(exception.recipient_variable).to eq('more_apples')
    end
  end
end
