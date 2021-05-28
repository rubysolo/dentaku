require 'dentaku/dependency_resolver'
require 'dentaku/exceptions'
require 'dentaku/flat_hash'
require 'dentaku/parser'
require 'dentaku/tokenizer'

module Dentaku
  class BulkExpressionSolver
    def initialize(expressions, calculator)
      @expression_hash = FlatHash.from_hash(expressions)
      @calculator = calculator
    end

    def solve!
      solve(&raise_exception_handler)
    end

    def solve(&block)
      error_handler = block || return_undefined_handler
      results = load_results(&error_handler)

      FlatHash.expand(
        expression_hash.each_with_object({}) do |(k, v), r|
          default = v.nil? ? v : :undefined
          r[k] = results.fetch(k.to_s, default)
        end
      )
    end

    def dependencies
      Hash[expression_deps].tap do |d|
        d.values.each do |deps|
          unresolved = deps.reject { |ud| d.has_key?(ud) }
          unresolved.each { |u| add_dependencies(d, u) }
        end
      end
    end

    private

    def self.dependency_cache
      @dep_cache ||= {}
    end

    attr_reader :expression_hash, :calculator

    def return_undefined_handler
      ->(*) { :undefined }
    end

    def raise_exception_handler
      ->(ex) { raise ex }
    end

    def expression_with_exception_handler(&block)
      ->(_expr, ex) { block.call(ex) }
    end

    def load_results(&block)
      facts, _formulas = expressions.transform_keys(&:downcase)
                                    .transform_values { |v| calculator.ast(v) }
                                    .partition { |_, v| calculator.dependencies(v, nil).empty? }

      evaluated_facts = facts.to_h.each_with_object({}) do |(var_name, ast), h|
        with_rescues(var_name, h, block) do
          h[var_name] = ast.is_a?(Array) ? ast.map(&:value) : ast.value
        end
      end

      context = calculator.memory.merge(evaluated_facts)

      variables_in_resolve_order.each_with_object({}) do |var_name, results|
        next if expressions[var_name].nil?

        with_rescues(var_name, results, block) do
          results[var_name] = evaluated_facts[var_name] || calculator.evaluate!(
            expressions[var_name],
            context.merge(results),
            &expression_with_exception_handler(&block)
          )
        end
      end

    rescue TSort::Cyclic => ex
      block.call(ex)
      {}
    end

    def with_rescues(var_name, results, block)
      yield

    rescue UnboundVariableError,  Dentaku::ZeroDivisionError => ex
      ex.recipient_variable = var_name
      results[var_name] = block.call(ex)

    rescue Dentaku::ArgumentError => ex
      results[var_name] = block.call(ex)

    ensure
      if results[var_name] == :undefined && calculator.memory.has_key?(var_name.downcase)
        results[var_name] = calculator.memory[var_name.downcase]
      end
    end

    def expressions
      @expressions ||= Hash[expression_hash.map { |k, v| [k.to_s, v] }]
    end

    def expression_deps
      expressions.map do |var, expr|
        [var, calculator.dependencies(expr)]
      end
    end

    def add_dependencies(current_dependencies, variable)
      node = calculator.memory[variable]
      if node.respond_to?(:dependencies)
        current_dependencies[variable] = node.dependencies
        node.dependencies.each { |d| add_dependencies(current_dependencies, d) }
      end
    end

    def variables_in_resolve_order
      cache_key = expressions.keys.map(&:to_s).sort.join("|")
      @ordered_deps ||= self.class.dependency_cache.fetch(cache_key) {
        DependencyResolver.find_resolve_order(dependencies).tap do |d|
          self.class.dependency_cache[cache_key] = d if Dentaku.cache_dependency_order?
        end
      }
    end
  end
end
