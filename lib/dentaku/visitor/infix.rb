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

      def process(_ast)
        raise NotImplementedError
      end

      def visit_function(node)
        node.args.each do |arg|
          visit(arg)
        end
        process(node)
      end

      def visit_identifier(node)
        process(node)
      end

      def visit_operation(node)
        visit(node.left) if node.left
        process(node)
        visit(node.right) if node.right
      end

      def visit_operand(node)
        process(node)
      end

      def visit_case(node)
        process(node)
      end

      def visit_switch(node)
        process(node)
        end

      def visit_case_conditional(node)
        process(node)
      end

      def visit_when(node)
        process(node)
      end

      def visit_then(node)
        process(node)
      end

      def visit_else(node)
        process(node)
      end

      def visit_negation(node)
        process(node)
      end

      def visit_access(node)
        process(node)
      end

      def visit_literal(node)
        process(node)
      end

      def visit_nil(node)
        process(node)
      end

      def visit_array(node)
        process(node)
      end
    end
  end
end