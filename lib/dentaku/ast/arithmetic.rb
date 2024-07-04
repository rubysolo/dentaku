require_relative './operation'
require_relative '../date_arithmetic'
require 'bigdecimal'
require 'bigdecimal/util'

module Dentaku
  module AST
    class Arithmetic < Operation
      DECIMAL = /\A-?\d*\.\d+\z/.freeze
      INTEGER = /\A-?\d+\z/.freeze

      def initialize(*)
        super

        unless valid_left?
          raise NodeError.new(:numeric, left.type, :left),
                "#{self.class} requires numeric operands"
        end

        unless valid_right?
          raise NodeError.new(:numeric, right.type, :right),
                "#{self.class} requires numeric operands"
        end
      end

      def type
        :numeric
      end

      def operator
        raise NotImplementedError
      end

      def value(context = {})
        calculate(left.value(context), right.value(context))
      end

      private

      def calculate(left_value, right_value)
        l = cast(left_value)
        r = cast(right_value)

        l.public_send(operator, r)
      rescue ::TypeError => e
        # Right cannot be converted to a suitable type for left. e.g. [] + 1
        raise Dentaku::ArgumentError.for(:incompatible_type, value: r, for: l.class), e.message
      end

      def cast(val)
        validate_value(val)
        numeric(val)
      end

      def numeric(val)
        case val.to_s
        when DECIMAL then decimal(val)
        when INTEGER then val.to_i
        else val
        end
      end

      def decimal(val)
        BigDecimal(val.to_s, Float::DIG + 1)
      rescue # return as is, in case value can't be coerced to big decimal
        val
      end

      def datetime?(val)
        # val is a Date, Time, or DateTime
        return true if val.respond_to?(:strftime)

        val.to_s =~ Dentaku::TokenScanner::DATE_TIME_REGEXP
      end

      def valid_node?(node)
        node && (node.type == :numeric || node.type == :integer || node.dependencies.any?)
      end

      def valid_left?
        valid_node?(left) || left.type == :datetime
      end

      def valid_right?
        valid_node?(right) || right.type == :duration || right.type == :datetime
      end

      def validate_value(val)
        if val.is_a?(::String)
          validate_format(val)
        else
          validate_operation(val)
        end
      end

      def validate_operation(val)
        unless val.respond_to?(operator)
          raise Dentaku::ArgumentError.for(:invalid_operator, operation: self.class, operator: operator),
                "#{ self.class } requires operands that respond to #{operator}"
        end
      end

      def validate_format(string)
        unless string =~ /\A-?\d*(\.\d+)?\z/ && !string.empty?
          raise Dentaku::ArgumentError.for(:invalid_value, value: string, for: BigDecimal),
                "String input '#{string}' is not coercible to numeric"
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

      def value(context = {})
        left_value = left.value(context)
        right_value = right.value(context)

        if left.type == :datetime || datetime?(left_value)
          Dentaku::DateArithmetic.new(left_value).add(right_value)
        else
          calculate(left_value, right_value)
        end
      end
    end

    class Subtraction < Arithmetic
      def operator
        :-
      end

      def self.precedence
        10
      end

      def value(context = {})
        left_value = left.value(context)
        right_value = right.value(context)

        if left.type == :datetime || datetime?(left_value)
          Dentaku::DateArithmetic.new(left_value).sub(right_value)
        else
          calculate(left_value, right_value)
        end
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

      def value(context = {})
        r = decimal(cast(right.value(context)))
        raise Dentaku::ZeroDivisionError if r.zero?

        cast(cast(left.value(context)) / r)
      end

      def self.precedence
        20
      end
    end

    class Modulo < Arithmetic
      def self.arity
        2
      end

      def self.precedence
        20
      end

      def self.resolve_class(next_token)
        next_token.nil? || next_token.operator? || next_token.close? ? Percentage : self
      end

      def operator
        :%
      end
    end

    class Percentage < Arithmetic
      def self.arity
        1
      end

      def initialize(child)
        @right = child

        unless valid_right?
          raise NodeError.new(:numeric, right.type, :right),
                "#{self.class} requires a numeric operand"
        end
      end

      def dependencies(context = {})
        @right.dependencies(context)
      end

      def value(context = {})
        cast(right.value(context)) * 0.01
      end

      def operator
        :%
      end

      def self.precedence
        30
      end
    end

    class Exponentiation < Arithmetic
      def operator
        :**
      end

      def display_operator
        "^"
      end

      def self.precedence
        30
      end
    end
  end
end
