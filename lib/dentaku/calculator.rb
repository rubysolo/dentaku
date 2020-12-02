require 'dentaku/bulk_expression_solver'
require 'dentaku/dependency_resolver'
require 'dentaku/exceptions'
require 'dentaku/flat_hash'
require 'dentaku/parser'
require 'dentaku/string_casing'
require 'dentaku/token'

module Dentaku
  class Calculator
    include StringCasing
    attr_reader :result, :memory, :tokenizer, :case_sensitive, :aliases,
                :nested_data_support, :ast_cache

    def initialize(options = {})
      clear
      @tokenizer = Tokenizer.new
      @case_sensitive = options.delete(:case_sensitive)
      @aliases = options.delete(:aliases) || Dentaku.aliases
      @nested_data_support = options.fetch(:nested_data_support, true)
      options.delete(:nested_data_support)
      @ast_cache = options
      @disable_ast_cache = false
      @function_registry = Dentaku::AST::FunctionRegistry.new
    end

    def self.add_function(name, type, body)
      Dentaku::AST::FunctionRegistry.default.register(name, type, body)
    end

    def add_function(name, type, body)
      @function_registry.register(name, type, body)
      self
    end

    def add_functions(fns)
      fns.each { |(name, type, body)| add_function(name, type, body) }
      self
    end

    def disable_cache
      @disable_ast_cache = true
      yield(self) if block_given?
    ensure
      @disable_ast_cache = false
    end

    def evaluate(expression, data = {}, &block)
      evaluate!(expression, data)
    rescue Dentaku::Error, Dentaku::ArgumentError, Dentaku::ZeroDivisionError => ex
      block.call(expression, ex) if block_given?
    end

    def evaluate!(expression, data = {}, &block)
      return expression.map { |e|
        evaluate(e, data, &block)
      } if expression.is_a? Array

      store(data) do
        node = expression
        node = ast(node) unless node.is_a?(AST::Node)
        unbound = node.dependencies - memory.keys
        unless unbound.empty?
          raise UnboundVariableError.new(unbound),
                "no value provided for variables: #{unbound.uniq.join(', ')}"
        end
        node.value(memory)
      end
    end

    def solve!(expression_hash)
      BulkExpressionSolver.new(expression_hash, self).solve!
    end

    def solve(expression_hash, &block)
      BulkExpressionSolver.new(expression_hash, self).solve(&block)
    end

    def dependencies(expression, context = {})
      test_context = context.nil? ? {} : store(context) { memory }

      case expression
      when Dentaku::AST::Node
        expression.dependencies(test_context)
      when Array
        expression.flat_map { |e| dependencies(e, context) }
      else
        ast(expression).dependencies(test_context)
      end
    end

    def ast(expression)
      return expression.map { |e| ast(e) } if expression.is_a? Array

      @ast_cache.fetch(expression) {
        options = {
          case_sensitive: case_sensitive,
          function_registry: @function_registry,
          aliases: aliases
        }

        tokens = tokenizer.tokenize(expression, options)
        Parser.new(tokens, options).parse.tap do |node|
          @ast_cache[expression] = node if cache_ast?
        end
      }
    end

    def load_cache(ast_cache)
      @ast_cache = ast_cache
    end

    def clear_cache(pattern = :all)
      case pattern
      when :all
        @ast_cache = {}
      when String
        @ast_cache.delete(pattern)
      when Regexp
        @ast_cache.delete_if { |k, _| k =~ pattern }
      else
        raise ::ArgumentError
      end
    end

    def store(key_or_hash, value = nil)
      restore = Hash[memory]

      if value.nil?
        key_or_hash = FlatHash.from_hash_with_intermediates(key_or_hash) if nested_data_support
        key_or_hash.each do |key, val|
          memory[standardize_case(key.to_s)] = val
        end
      else
        memory[standardize_case(key_or_hash.to_s)] = value
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

    def cache_ast?
      Dentaku.cache_ast? && !@disable_ast_cache
    end
  end
end
