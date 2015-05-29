require 'dentaku/calculator'
require 'dentaku/dependency_resolver'
require 'dentaku/exceptions'
require 'dentaku/expression'

module Dentaku
  class BulkExpressionSolver
    def initialize(expression_hash, memory)
      self.expression_hash = expression_hash
      self.memory = memory
    end

    def solve!
      solve(&raise_exception_handler)
    end

    def solve(&block)
      error_handler = block || return_undefined_handler
      results = load_results(&error_handler)

      expression_hash.each_with_object({}) do |(k, _), r|
        r[k] = results[k.to_s]
      end
    end

    private

    attr_accessor :expression_hash, :memory

    def return_undefined_handler
      ->(*) { :undefined }
    end

    def raise_exception_handler
      ->(ex) { raise ex }
    end

    def load_results(&block)
      variables_in_resolve_order.each_with_object({}) do |var_name, r|
        begin
          r[var_name] = evaluate!(expressions[var_name], r)
        rescue Dentaku::UnboundVariableError, ZeroDivisionError => ex
          r[var_name] = block.call(ex)
        end
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

    def calculator
      @calculator ||= Calculator.new.store(memory)
    end
  end
end
