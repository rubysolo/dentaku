require_relative './operation'

module Dentaku
  module AST
    class Arithmetic < Operation
      def initialize(*)
        super
        fail "#{ self.class } requires numeric operands" unless valid_node?(left) && valid_node?(right)
      end

      def type
        :numeric
      end

      private

      def valid_node?(node)
        node.is_a?(Identifier) || node.type == :numeric
      end
    end

    class Addition < Arithmetic
      def value(context={})
        left.value(context) + right.value(context)
      end

      def self.precedence
        10
      end
    end

    class Subtraction < Arithmetic
      def value(context={})
        left.value(context) - right.value(context)
      end

      def self.precedence
        10
      end
    end

    class Multiplication < Arithmetic
      def value(context={})
        left.value(context) * right.value(context)
      end

      def self.precedence
        20
      end
    end

    class Division < Arithmetic
      def value(context={})
        left.value(context) / right.value(context)
      end

      def self.precedence
        20
      end
    end

    class Exponentiation < Arithmetic
      def value(context={})
        left.value(context) ** right.value(context)
      end

      def self.precedence
        30
      end
    end
  end
end
