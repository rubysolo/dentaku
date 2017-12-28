module Dentaku
  module AST
    class CaseElse < Node
      attr_reader :node

      def self.arity
        1
      end

      def initialize(node)
        @node = node
      end

      def value(context = {})
        @node.value(context)
      end

      def dependencies(context = {})
        @node.dependencies(context)
      end

      def accept(visitor)
        visitor.visit_else(self)
      end
    end
  end
end
