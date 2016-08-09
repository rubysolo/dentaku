require_relative './operation'
require 'bigdecimal'
require 'bigdecimal/util'

module Dentaku
  module AST
    class Arithmetic < Operation
      def initialize(*)
        super
        unless valid_node?(left) && valid_node?(right)
          fail ParseError, "#{ self.class } requires numeric operands"
        end
      end

      def type
        :numeric
      end

      def value(context={})
        l = cast(left.value(context))
        r = cast(right.value(context))
        l.public_send(operator, r)
      end

      private

      def cast(value, prefer_integer=true)
        validate_numeric(value)
        v = BigDecimal.new(value, Float::DIG+1)
        v = v.to_i if prefer_integer && v.frac.zero?
        v
      end

      def valid_node?(node)
        node && (node.dependencies.any? || node.type == :numeric)
      end

      def validate_numeric(value)
        Float(value)
      rescue ::ArgumentError, ::TypeError
        fail Dentaku::ArgumentError, "#{ self.class } requires numeric operands"
      end
    end

    class Addition < Arithmetic
      def operator
        :+
      end

      def self.precedence
        10
      end
    end

    class Subtraction < Arithmetic
      def operator
        :-
      end

      def self.precedence
        10
      end
    end

    class Multiplication < Arithmetic
      def operator
        :*
      end

      def self.precedence
        20
      end
    end

    class Division < Arithmetic
      def value(context={})
        r = cast(right.value(context), false)
        raise Dentaku::ZeroDivisionError if r.zero?

        cast(cast(left.value(context)) / r)
      end

      def self.precedence
        20
      end
    end

    class Modulo < Arithmetic
      def initialize(left, right)
        @left  = left
        @right = right

        unless (valid_node?(left) || left.nil?) && valid_node?(right)
          fail ParseError, "#{ self.class } requires numeric operands"
        end
      end

      def percent?
        left.nil?
      end

      def value(context={})
        if percent?
          cast(right.value(context)) * 0.01
        else
          super
        end
      end

      def operator
        :%
      end

      def self.precedence
        20
      end
    end

    class Exponentiation < Arithmetic
      def operator
        :**
      end

      def self.precedence
        30
      end
    end
  end
end
