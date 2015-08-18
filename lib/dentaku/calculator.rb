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
      @ast_cache = {}
    end

    def add_function(name, type, body)
      Dentaku::AST::Function.register(name, type, body)
      self
    end

    def add_functions(fns)
      fns.each { |(name, type, body)| add_function(name, type, body) }
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
      @ast_cache.fetch(expression) {
        Parser.new(tokenizer.tokenize(expression)).parse.tap do |node|
          @ast_cache[expression] = node if Dentaku.cache_ast?
        end
      }
    end

    def store(key_or_hash, value=nil)
      restore = Hash[memory]

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
