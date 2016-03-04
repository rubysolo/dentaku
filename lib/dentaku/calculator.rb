require 'dentaku'
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
    rescue UnboundVariableError, ArgumentError
      yield expression if block_given?
    end

    def evaluate!(expression, data={})
      store(data) do
        node = expression
        node = ast(node) unless node.is_a?(AST::Node)
        node.value(memory)
      end
    end

    def solve!(expression_hash)
      BulkExpressionSolver.new(expression_hash, self).solve!
    end

    def solve(expression_hash, &block)
      BulkExpressionSolver.new(expression_hash, self).solve(&block)
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
          memory[key.to_s.downcase] = val
        end
      else
        memory[key_or_hash.to_s.downcase] = value
      end

      if block_given?
        begin
          result = yield
          @memory = restore
          return result
        rescue => e
          @memory = restore
          raise e
        end
      end

      self
    end
    alias_method :bind, :store

    def store_formula(key, formula)
      store(key, ast(formula))
    end

    def clear
      @memory = {}
    end

    def empty?
      memory.empty?
    end
  end
end
