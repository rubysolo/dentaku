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
    end
  end
end
