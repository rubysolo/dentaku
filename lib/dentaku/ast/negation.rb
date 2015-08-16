module Dentaku
  module AST
    class Negation < Operation
      def initialize(node)
        @node = node
        fail "Negation requires numeric operand" unless valid_node?(node)
      end

      def value(context={})
        @node.value(context) * -1
      end

      def type
        :numeric
      end

      def self.arity
        1
      end

      def self.right_associative?
        true
      end

      def self.precedence
        40
      end

      private

      def valid_node?(node)
        node.is_a?(Identifier) || node.type == :numeric
      end
    end
  end
end
