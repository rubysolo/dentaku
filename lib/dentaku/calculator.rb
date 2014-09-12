require 'dentaku/evaluator'
require 'dentaku/expression'
require 'dentaku/rules'
require 'dentaku/token'
require 'dentaku/dependency_resolver'

module Dentaku
  class Calculator
    attr_reader :result

    def initialize
      clear
    end

    def add_function(fn)
      Rules.add_function(fn)
      self
    end

    def add_functions(fns)
      fns.each { |fn| Rules.add_function(fn) }
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
        @evaluator ||= Evaluator.new
        @result = @evaluator.evaluate(expr.tokens)
      end
    end

    def solve!(expression_hash)
      # expression_hash: { variable_name: "string expression" }
      # TSort thru the expressions' dependencies, then evaluate all
      expression_dependencies = Hash[expression_hash.map do |var, expr|
        [var, dependencies(expr)]
      end]
      variables_in_resolve_order = DependencyResolver::find_resolve_order(
        expression_dependencies)

      results = {}
      variables_in_resolve_order.each do |var_name|
        results[var_name] = evaluate!(expression_hash[var_name], results)
      end

      results
    end

    def dependencies(expression)
      Expression.new(expression, @memory).identifiers
    end

    def store(key_or_hash, value=nil)
      restore = @memory.dup

      if !value.nil?
        @memory[key_or_hash.to_sym] = value
      else
        key_or_hash.each do |key, value|
          @memory[key.to_sym] = value
        end
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
