require 'dentaku/bulk_expression_solver'
require 'dentaku/evaluator'
require 'dentaku/exceptions'
require 'dentaku/expression'
require 'dentaku/rule_set'
require 'dentaku/token'
require 'dentaku/dependency_resolver'

module Dentaku
  class Calculator
    attr_reader :result, :rule_set

    def initialize
      clear
      @rule_set = RuleSet.new
    end

    def add_function(fn)
      rule_set.add_function(fn)
      self
    end

    def add_functions(fns)
      fns.each { |fn| add_function(fn) }
      self
    end

    def evaluate(expression, data={})
      evaluate!(expression, data)
    rescue UnboundVariableError
      yield expression if block_given?
    end

    def evaluate!(expression, data={})
      store(data) do
        expr = Expression.new(expression, @memory)
        raise UnboundVariableError.new(expr.identifiers) if expr.unbound?
        @evaluator ||= Evaluator.new(rule_set)
        @result = @evaluator.evaluate(expr.tokens)
      end
    end

    def solve!(expression_hash)
      BulkExpressionSolver.new(expression_hash, @memory).solve!
    end

    def solve(expression_hash, &block)
      BulkExpressionSolver.new(expression_hash, @memory).solve(&block)
    end

    def dependencies(expression)
      Expression.new(expression, @memory).identifiers
    end

    def store(key_or_hash, value=nil)
      restore = @memory.dup

      if value.nil?
        key_or_hash.each do |key, val|
          @memory[key.downcase.to_s] = val
        end
      else
        @memory[key_or_hash.to_s] = value
      end

      if block_given?
        result = yield
        @memory = restore
        return result
      end

      self
    end
    alias_method :bind, :store

    def clear
      @memory = {}
    end

    def empty?
      @memory.empty?
    end
  end
end
