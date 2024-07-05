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
                :nested_data_support, :ast_cache, :raw_date_literals

    def initialize(options = {})
      clear
      @tokenizer = Tokenizer.new
      @case_sensitive = options.delete(:case_sensitive)
      @aliases = options.delete(:aliases) || Dentaku.aliases
      @nested_data_support = options.fetch(:nested_data_support, true)
      options.delete(:nested_data_support)
      @raw_date_literals = options.fetch(:raw_date_literals, true)
      options.delete(:raw_date_literals)
      @ast_cache = options
      @disable_ast_cache = false
      @function_registry = Dentaku::AST::FunctionRegistry.new
    end

    def self.add_function(name, type, body, callback = nil)
      Dentaku::AST::FunctionRegistry.default.register(name, type, body, callback)
    end

    def self.add_functions(functions)
      functions.each { |(name, type, body, callback)| add_function(name, type, body, callback) }
    end

    def add_function(name, type, body, callback = nil)
      @function_registry.register(name, type, body, callback)
      self
    end

    def add_functions(functions)
      functions.each { |(name, type, body, callback)| add_function(name, type, body, callback) }
      self
    end

    def disable_cache
      @disable_ast_cache = true
      yield(self) if block_given?
    ensure
      @disable_ast_cache = false
    end

    def evaluate(expression, data = {}, &block)
      context = evaluation_context(data, :permissive)
      return evaluate_array(expression, context, &block) if expression.is_a?(Array)

      evaluate!(expression, context)
    rescue Dentaku::Error, Dentaku::ArgumentError, Dentaku::ZeroDivisionError => ex
      block.call(expression, ex) if block_given?
    end

    private def evaluate_array(expression, data = {}, &block)
      expression.map { |e| evaluate(e, data, &block) }
    end

    def evaluate!(expression, data = {}, &block)
      context = evaluation_context(data, :strict)
      return evaluate_array!(expression, context, &block) if expression.is_a? Array

      store(context) do
        node = ast(expression)
        unbound = node.dependencies(memory)

        unless unbound.empty?
          raise UnboundVariableError.new(unbound),
                "no value provided for variables: #{unbound.uniq.join(', ')}"
        end

        node.value(memory)
      end
    end

    private def evaluate_array!(expression, data = {}, &block)
      expression.map { |e| evaluate!(e, data, &block) }
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
      return expression if expression.is_a?(AST::Node)
      return expression.map { |e| ast(e) } if expression.is_a? Array

      @ast_cache.fetch(expression) {
        options = {
          aliases: aliases,
          case_sensitive: case_sensitive,
          function_registry: @function_registry,
          raw_date_literals: raw_date_literals
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

    def evaluation_context(data, evaluation_mode)
      data.key?(:__evaluation_mode) ? data : data.merge(__evaluation_mode: evaluation_mode)
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
