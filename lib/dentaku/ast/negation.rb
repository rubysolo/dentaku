module Dentaku
  module AST
    class Negation < Operation
      def initialize(node)
        @node = node
      end

      def value(context={})
        @node.value(context) * -1
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
    end
  end
end
