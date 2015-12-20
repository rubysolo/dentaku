module Dentaku
  module AST
    class CaseSwitchVariable < Node
      def initialize(node)
        @node = node
      end

      def value(context={})
        @node.value(context)
      end

      def dependencies(context={})
        @node.dependencies(context)
      end

      def self.arity
        1
      end
    end
  end
end
