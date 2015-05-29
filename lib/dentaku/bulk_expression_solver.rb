require 'dentaku/calculator'
require 'dentaku/dependency_resolver'
require 'dentaku/exceptions'
require 'dentaku/expression'

module Dentaku
  class BulkExpressionSolver
    def initialize(expression_hash, memory, calculator)
      self.expression_hash = expression_hash
      self.memory = memory
      self.calculator = calculator
    end

    def solve!
      results = load_results

      expression_hash.each_with_object({}) do |(k, _), r|
        r[k] = results[k.to_s]
      end
    end

    private

    attr_accessor :expression_hash, :memory, :calculator

    def load_results
      variables_in_resolve_order.each_with_object({}) do |var_name, r|
        r[var_name] = evaluate!(expressions[var_name], r)
      end
    end

    def dependencies(expression)
      Expression.new(expression, memory).identifiers
    end

    def expressions
      @expressions ||= Hash[expression_hash.map { |k,v| [k.to_s, v] }]
    end

    def expression_dependencies
      Hash[expressions.map { |var, expr| [var, dependencies(expr)] }]
    end

    def variables_in_resolve_order
      @variables_in_resolve_order ||=
        DependencyResolver::find_resolve_order(expression_dependencies)
    end

    def evaluate!(expression, results)
      expr = Expression.new(expression, memory.merge(expressions))
      raise UnboundVariableError.new(expr.identifiers) if expr.unbound?
      calculator.evaluate!(expression, results)
    end
  end
end
