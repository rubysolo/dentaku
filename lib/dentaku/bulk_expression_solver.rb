require 'dentaku/dependency_resolver'
require 'dentaku/exceptions'
require 'dentaku/flat_hash'
require 'dentaku/parser'
require 'dentaku/tokenizer'

module Dentaku
  class BulkExpressionSolver
    class StrictEvaluator
      def initialize(calculator)
        @calculator = calculator
      end

      def evaluate(*args, &block)
        @calculator.evaluate!(*args, &block)
      end
    end

    class PermissiveEvaluator
      def initialize(calculator, block)
        @calculator = calculator
        @block = block || ->(*) { :undefined }
      end

      def evaluate(*args, &block)
        handler = block || ->(_expr, ex) { @block.call(ex) }
        @calculator.evaluate(*args, &handler)
      end
    end

    def initialize(expressions, calculator)
      @expression_hash = FlatHash.from_hash(expressions)
      @calculator = calculator
    end

    def solve!
      @evaluator = StrictEvaluator.new(calculator)
      solve(&raise_exception_handler)
    end

    def solve(&block)
      @evaluator ||= PermissiveEvaluator.new(calculator, block)
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

    attr_reader :expression_hash, :calculator, :evaluator

    def return_undefined_handler
      ->(*) { :undefined }
    end

    def raise_exception_handler
      ->(ex) { raise ex }
    end

    def expression_with_exception_handler(var_name, &block)
      ->(_expr, ex) {
        ex.assigned_to = var_name
        block.call(ex)
      }
    end

    def load_results(&block)
      facts, _formulas = expressions.transform_keys { |k| normalized_name(k) }
                                    .transform_values { |v| calculator.ast(v) }
                                    .partition { |_, v| calculator.dependencies(v, nil).empty? }

      evaluated_facts = facts.to_h.each_with_object({}) do |(var_name, ast), h|
        with_rescues(var_name, h, block) do
          h[var_name] = fact_value(ast)
        end
      end

      context = calculator.memory.merge(evaluated_facts)

      variables_in_resolve_order.each_with_object({}) do |var_name, results|
        next if expressions[var_name].nil?

        with_rescues(var_name, results, block) do
          results[var_name] = evaluated_facts[normalized_name(var_name)] || evaluator.evaluate(
            expressions[var_name],
            context.merge(results),
            &expression_with_exception_handler(var_name, &block)
          ).tap { |res|
            res.assigned_to = var_name if res.respond_to?(:assigned_to=)
            res
          }
        end
      end

    rescue TSort::Cyclic => ex
      block.call(ex)
      {}
    end

    # facts can be arrays and hashes nested to any depth, e.g. [{ a: 1 }]
    def fact_value(ast)
      case ast
      when Array then ast.map { |a| fact_value(a) }
      when Hash then ast.transform_values { |a| fact_value(a) }
      else ast.value
      end
    end

    def with_rescues(var_name, results, block)
      yield
    rescue Dentaku::UnboundVariableError, Dentaku::ZeroDivisionError, Dentaku::ArgumentError => ex
      ex.assigned_to = var_name
      results[var_name] = block.call(ex)
    ensure
      stored_name = normalized_name(var_name)
      if results[var_name] == :undefined && calculator.memory.has_key?(stored_name)
        results[var_name] = calculator.memory[stored_name]
      end
    end

    # names are normalized the same way the calculator stores them, so that
    # facts and memory lookups line up with the identifiers the parser emits
    def normalized_name(variable_name)
      calculator.standardize_case(variable_name.to_s)
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

    # Stored memory can satisfy a formula's reference to another key being
    # solved, which hides that edge from `dependencies`. Order those keys first
    # anyway so the formula sees the solved value rather than the stored one,
    # unless the edge would close a cycle -- then the stored value is what
    # breaks it, as for self-referential formulas.
    def resolve_order_graph
      graph = dependencies
      keys = expressions.keys.map { |k| normalized_name(k) }

      hidden = expressions.to_h do |var, expr|
        own = normalized_name(var)
        visible = graph.fetch(var, []).map { |d| normalized_name(d) }
        all = Array(calculator.dependencies(expr, nil)).map { |d| normalized_name(d) }
        [var, (all & keys) - visible - [own]]
      end
      return graph if hidden.values.all?(&:empty?)

      with_hidden = graph.merge(hidden) { |_, deps, extra| deps + extra }
      cycle_of = {}
      DependencyResolver.cycles(with_hidden, calculator.case_sensitive).each_with_index do |cycle, i|
        cycle.each { |name| cycle_of[name] = i }
      end

      graph.merge(hidden) do |var, deps, extra|
        cycle = cycle_of[normalized_name(var)]
        deps + extra.reject { |e| cycle && cycle_of[e] == cycle }
      end
    end

    def variables_in_resolve_order
      @ordered_deps ||= begin
        dependency_graph = resolve_order_graph
        cache_key = [!!calculator.case_sensitive, dependency_graph]
        self.class.dependency_cache.fetch(cache_key) {
          DependencyResolver.find_resolve_order(dependency_graph, calculator.case_sensitive).tap do |d|
            self.class.dependency_cache[cache_key] = d if calculator.cache_dependency_order?
          end
        }
      end
    end
  end
end
