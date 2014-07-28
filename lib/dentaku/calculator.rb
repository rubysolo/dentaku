require 'dentaku/evaluator'
require 'dentaku/expression'
require 'dentaku/rules'
require 'dentaku/token'

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

    def store(key_or_hash, value=nil)
      restore = @memory.dup

      if value
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
