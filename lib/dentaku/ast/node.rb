module Dentaku
  module AST
    class Node
      # reserved context key (double-underscore prefix, like
      # __evaluation_mode) that switches dependencies() into static mode:
      # guards are never evaluated and every branch is reported
      STATIC_MODE_KEY = "__static_dependencies".freeze
      STATIC_CONTEXT = { STATIC_MODE_KEY => true }.freeze

      # reserved context key under which Calculator keeps, for the span of one
      # dependency resolution and the evaluation that follows it, the values
      # that probing short-circuit guards has already produced
      PROBE_CACHE_KEY = "__probe_cache".freeze

      def self.precedence
        0
      end

      def self.arity
        nil
      end

      def self.resolve_class(*)
        self
      end

      def dependencies(context = {})
        []
      end

      # whether this subtree may be evaluated during dependency resolution
      # without running volatile user code; a property of the parsed AST,
      # computed once and memoized
      def pure?
        return @pure if defined?(@pure)

        @pure = compute_pure?
      end

      def type
        nil
      end

      def name
        self.class.name.to_s.split("::").last.upcase
      end

      private

      def static_mode?(context)
        context[STATIC_MODE_KEY] == true
      end

      def probe_cache(context)
        context[PROBE_CACHE_KEY]
      end

      # dependency resolution has determined this node's value from operands
      # that are already bound: keep it so that neither an enclosing guard nor
      # #value has to compute it again, and report that nothing is unbound
      def settled(context, result)
        cache = probe_cache(context)
        cache[self] = result if cache
        []
      end

      # the branch a guard selects is bound and pure, so its value is this
      # node's value; computing it now costs nothing extra because evaluation
      # would run it anyway. A failure is left for #value to raise, so it
      # cannot widen the dependency report
      def settle_from(context, node)
        return unless probe_cache(context)

        settled(context, node.value(context))
      rescue Dentaku::Error
        nil
      end

      # yields unless dependency resolution already settled this node
      def remembered(context)
        cache = probe_cache(context)
        return cache[self] if cache&.key?(self)

        yield
      end

      def compute_pure?
        true
      end
    end
  end
end
