# infix visitor
#
# use this visitor in a processor to get infix visiting order
#
#  visitor     node     deps
#    accept ->   visit left ->
#                process
#                visit right ->
module Dentaku
  module Visitor
    module Infix
      def visit(ast)
        ast.accept(self)
      end

      def process(ast)
        # override with concrete implementation
      end

      def visit_literal(node)
        process(node)
      end

      def visit_operation(node)
        visit(node.left) if node.left
        process(node)
        visit(node.right) if node.right
      end
    end
  end
end