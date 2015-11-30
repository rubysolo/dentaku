module Dentaku
  module AST
    class CaseThen < Node
      def self.arity
        1
      end

      def initialize(node)
        @node = node
      end

      def value(context={})
        @node.value(context)
      end

      def dependencies(context={})
        @node.dependencies(context)
      end
    end
  end
end
