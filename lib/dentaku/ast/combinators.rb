require_relative './operation'

module Dentaku
  module AST
    class Combinator < Operation
      def initialize(*)
        super

        unless valid_node?(left)
          raise NodeError.new(:logical, left.type, :left),
                "#{self.class} requires logical operands"
        end
        unless valid_node?(right)
          raise NodeError.new(:logical, right.type, :right),
                "#{self.class} requires logical operands"
        end
      end

      def type
        :logical
      end

      private

      def valid_node?(node)
        node && (node.dependencies.any? || node.type == :logical)
      end
    end

    class And < Combinator
      def operator
        :and
      end

      def value(context = {})
        left.value(context) && right.value(context)
      end
    end

    class Or < Combinator
      def operator
        :or
      end

      def value(context = {})
        left.value(context) || right.value(context)
      end
    end
  end
end
