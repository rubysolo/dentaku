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
        expression_hash.each_with_object({}) do |(k, _), r|
          r[k] = results[k.to_s]
        end
      )
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

    def load_results(&block)
      variables_in_resolve_order.each_with_object({}) do |var_name, r|
        begin
          solved = calculator.memory
          value_from_memory = solved[var_name.downcase]

          if value_from_memory.nil? &&
              expressions[var_name].nil? &&
              !solved.has_key?(var_name)
            next
          end

          value = value_from_memory ||
            evaluate!(expressions[var_name], expressions.merge(r).merge(solved))

          r[var_name] = value
        rescue UnboundVariableError, Dentaku::ZeroDivisionError => ex
          ex.recipient_variable = var_name
          r[var_name] = block.call(ex)
        rescue Dentaku::ArgumentError => ex
          r[var_name] = block.call(ex)
        end
      end
    end

    def expressions
      @expressions ||= Hash[expression_hash.map { |k,v| [k.to_s, v] }]
    end

    def expression_deps
      expressions.map do |var, expr|
        [var, calculator.dependencies(expr)]
      end
    end

    def expression_dependencies
      Hash[expression_deps].tap do |d|
        d.values.each do |deps|
          unresolved = deps.reject { |ud| d.has_key?(ud) }
          unresolved.each { |u| add_dependencies(d, u) }
        end
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
        DependencyResolver.find_resolve_order(expression_dependencies).tap do |d|
          self.class.dependency_cache[cache_key] = d if Dentaku.cache_dependency_order?
        end
      }
    end

    def evaluate!(expression, results)
      calculator.evaluate!(expression, results)
    end
  end
end
