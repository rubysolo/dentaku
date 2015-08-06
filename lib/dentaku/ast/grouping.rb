module Dentaku
  module AST
    class Grouping
      def initialize(node)
        @node = node
      end

      def value(context={})
        @node.value(context)
      end
    end
  end
end
