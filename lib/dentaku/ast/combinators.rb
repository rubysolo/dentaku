require_relative './operation'

module Dentaku
  module AST
    class Combinator < Operation
      def initialize(*)
        super
        unless valid_node?(left) && valid_node?(right)
          fail ParseError, "#{ self.class } requires logical operands"
        end
      end

      def type
        :logical
      end

      private

      def valid_node?(node)
        node.dependencies.any? || node.type == :logical
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
