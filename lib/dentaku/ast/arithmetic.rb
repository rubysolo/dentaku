require_relative './operation'
require 'bigdecimal'
require 'bigdecimal/util'

module Dentaku
  module AST
    class Arithmetic < Operation
      def initialize(*)
        super
        unless valid_left? && valid_right?
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

      def valid_left?
        valid_node?(left)
      end

      def valid_right?
        valid_node?(right)
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

      def valid_left?
        valid_node?(left) || left.nil?
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
