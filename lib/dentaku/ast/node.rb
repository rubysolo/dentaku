module Dentaku
  module AST
    class Node
      # reserved context key (double-underscore prefix, like
      # __evaluation_mode) that switches dependencies() into static mode:
      # guards are never evaluated and every branch is reported
      STATIC_MODE_KEY = "__static_dependencies".freeze
      STATIC_CONTEXT = { STATIC_MODE_KEY => true }.freeze

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

      def compute_pure?
        true
      end
    end
  end
end
