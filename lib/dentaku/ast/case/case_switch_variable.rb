module Dentaku
  module AST
    class CaseSwitchVariable < Node
      attr_reader :node

      def initialize(node)
        @node = node
      end

      def value(context = {})
        @node.value(context)
      end

      def dependencies(context = {})
        @node.dependencies(context)
      end

      def self.arity
        1
      end

      def accept(visitor)
        visitor.visit_switch(self)
      end
    end
  end
end
