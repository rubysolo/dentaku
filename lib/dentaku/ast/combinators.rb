require_relative './operation'

module Dentaku
  module AST
    class Combinator < Operation
      def initialize(*)
        super
        fail "#{ self.class } requires logical operands" unless valid_node?(left) && valid_node?(right)
      end

      private

      def valid_node?(node)
        node.is_a?(Identifier) || node.type == :logical
      end
    end

    class And < Combinator
      def value(context={})
        left.value(context) && right.value(context)
      end
    end

    class Or < Combinator
      def value(context={})
        left.value(context) || right.value(context)
      end
    end
  end
end
