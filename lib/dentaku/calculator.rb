require 'dentaku/bulk_expression_solver'
require 'dentaku/exceptions'
require 'dentaku/token'
require 'dentaku/dependency_resolver'
require 'dentaku/parser'

module Dentaku
  class Calculator
    attr_reader :result, :memory, :tokenizer

    def initialize
      clear
      @tokenizer = Tokenizer.new
    end

    def add_function(fn)
      Dentaku::AST::Function.register(fn[:name], fn[:type], fn[:signature], fn[:body])
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
      memory[expression] || store(data) do
        node = expression
        node = ast(node) unless node.is_a?(AST::Node)
        node.value(memory)
      end
    end

    def solve!(expression_hash)
      BulkExpressionSolver.new(expression_hash, memory).solve!
    end

    def solve(expression_hash, &block)
      BulkExpressionSolver.new(expression_hash, memory).solve(&block)
    end

    def dependencies(expression)
      ast(expression).dependencies(memory)
    end

    def ast(expression)
      Parser.new(tokenizer.tokenize(expression)).parse
    end

    def store(key_or_hash, value=nil)
      restore = memory.dup

      if value.nil?
        key_or_hash.each do |key, val|
          memory[key.downcase.to_s] = val
        end
      else
        memory[key_or_hash.to_s] = value
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
      memory.empty?
    end
  end
end
