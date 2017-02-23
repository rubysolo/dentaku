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

      def operator
        raise "Not implemented"
      end

      def value(context={})
        l = cast(left.value(context))
        r = cast(right.value(context))
        l.public_send(operator, r)
      end

      private

      def cast(val, prefer_integer=true)
        validate_operation(val)
        validate_format(val) if val.is_a?(::String)
        numeric(val, prefer_integer)
      end

      def numeric(val, prefer_integer)
        v = BigDecimal.new(val, Float::DIG+1)
        v = v.to_i if prefer_integer && v.frac.zero?
        v
      rescue ::TypeError
        # If we got a TypeError BigDecimal or to_i failed;
        # let value through so ruby things like Time - integer work
        val
      end

      def valid_node?(node)
        node && (node.dependencies.any? || node.type == :numeric)
      end

      def validate_operation(val)
        unless val.respond_to?(operator)
          fail Dentaku::ArgumentError, "#{ self.class } requires operands that respond to #{ operator }"
        end
      end

      def validate_format(string)
        unless string =~ /\A-?\d+(\.\d+)?\z/
          fail Dentaku::ArgumentError, "String input '#{ string }' is not coercible to numeric"
        end
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
      def operator
        :/
      end

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
