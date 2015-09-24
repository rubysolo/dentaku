module Dentaku
  module AST
    class Grouping
      def initialize(node)
        @node = node
      end

      def value(context={})
        @node.value(context)
      end

      def type
        @node.type
      end

      def dependencies(context={})
        @node.dependencies(context)
      end
    end
  end
end
