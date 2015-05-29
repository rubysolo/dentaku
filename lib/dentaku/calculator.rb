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
      expressions = Hash[expression_hash.map { |k,v| [k.to_s, v] }]

      # expression_hash: { variable_name: "string expression" }
      # TSort thru the expressions' dependencies, then evaluate all
      expression_dependencies = Hash[expressions.map do |var, expr|
        [var, dependencies(expr)]
      end]

      variables_in_resolve_order = DependencyResolver::find_resolve_order(
        expression_dependencies)

      results = variables_in_resolve_order.each_with_object({}) do |var_name, r|
        expr = Expression.new(expressions[var_name], @memory.merge(expressions))
        raise UnboundVariableError.new(expr.identifiers) if expr.unbound?
        r[var_name] = evaluate!(expressions[var_name], r)
      end

      expression_hash.each_with_object({}) do |(k, _), r|
        r[k] = results[k.to_s]
      end
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
