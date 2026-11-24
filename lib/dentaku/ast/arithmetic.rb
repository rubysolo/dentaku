require_relative './operation'
require_relative '../date_arithmetic'
require_relative '../numeric_limits'
require 'bigdecimal'
require 'bigdecimal/util'

module Dentaku
  module AST
    class Arithmetic < Operation
      def initialize(*)
        super

        unless valid_left?
          raise NodeError.new(:incompatible, left.type, :left),
                "#{self.class} requires operands that are numeric or compatible types, not #{left.type}"
        end

        unless valid_right?
          raise NodeError.new(:incompatible, right.type, :right),
                "#{self.class} requires operands that are numeric or compatible types, not #{right.type}"
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
        check_operands!(l, r)

        result = begin
          l.public_send(operator, r)
        rescue ::TypeError => e
          # Right cannot be converted to a suitable type for left. e.g. [] + 1
          raise Dentaku::ArgumentError.for(:incompatible_type, actual: r, expected: l.class), e.message
        rescue Dentaku::Error
          # already one of ours (e.g. from arithmetic on a custom class)
          raise
        rescue ::ArgumentError, ::RangeError, ::FloatDomainError => e
          # the operation itself rejected an otherwise well-typed operand,
          # e.g. BigDecimal#** with an oversized exponent. Without this, a raw
          # Ruby exception escapes the non-bang Calculator#evaluate, which
          # promises to return nil rather than raise.
          raise Dentaku::ArgumentError.for(:invalid_value, actual: r), e.message
        end

        validate_result(result, l, r)
      end

      # Not every Ruby rejects an operation it cannot carry out. Before 3.4,
      # `Integer#**` with an oversized exponent warns and returns
      # Float::INFINITY where 3.4+ raises ArgumentError, and overflowing float
      # arithmetic is silently infinite on every version. Finite operands that
      # produce a non-finite result mean the operation overflowed, so treat it
      # as the same rejection newer Rubies raise -- otherwise Infinity leaks
      # out of Calculator#evaluate, which promises nil on failure (#332).
      def validate_result(result, l, r)
        Dentaku::NumericLimits.check!(result)
        return result unless nonfinite?(result)
        return result if nonfinite?(l) || nonfinite?(r)

        raise Dentaku::ArgumentError.for(:invalid_value, actual: r),
              "Result of #{l} #{operator} #{r} is not a finite number"
      end

      def nonfinite?(val)
        val.is_a?(::Numeric) && val.respond_to?(:finite?) && !val.finite?
      end

      # Hook for operators that can build a huge number from small operands
      def check_operands!(_l, _r); end

      def cast(val)
        validate_value(val)
        # strings here already match the numeric format; ensure_numeric! also
        # rejects numbers past NumericLimits::MAX_DIGITS
        return Dentaku::NumericParser.ensure_numeric!(val) if val.is_a?(::Numeric) || val.is_a?(::String)

        val
      end

      def decimal(val)
        BigDecimal(val.to_s, Float::DIG + 1)
      rescue # return as is, in case value can't be coerced to big decimal
        val
      end

      def datetime?(val)
        # val is a Date, Time, or DateTime
        return true if val.respond_to?(:strftime)
        return false unless val.is_a?(::String)

        val =~ Dentaku::TokenScanner::DATE_TIME_REGEXP
      end

      def valid_node?(node)
        return false unless node

        # Allow nodes with dependencies (identifiers that will be resolved later).
        # Ask statically: this runs while the parser is building the node, and
        # a non-static dependency check evaluates short-circuit guards, which
        # would execute user functions at parse time (#197).
        return true if node.dependencies(Node::STATIC_CONTEXT).any?

        # Allow compatible types
        return true if [:numeric, :integer, :array].include?(node.type)

        # Allow nodes without a type (operations, groupings)
        return true if node.type.nil?

        # Reject incompatible types
        false
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
          raise Dentaku::ArgumentError.for(:invalid_operator, operation: self.class, operator: operator)
        end
      end

      def validate_format(string)
        unless Dentaku::NumericParser.match(string)
          raise Dentaku::ArgumentError.for(:invalid_value, actual: string, expected: BigDecimal),
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

      def value(context = {})
        r = decimal(cast(right.value(context)))
        raise Dentaku::ZeroDivisionError if r.zero?

        cast(cast(left.value(context)) % r)
      end
    end

    class Percentage < Arithmetic
      def self.arity
        1
      end

      def initialize(child)
        @left = child

        unless valid_left?
          raise NodeError.new(:numeric, left.type, :left),
                "#{self.class} requires a numeric operand"
        end
      end

      def dependencies(context = {})
        @left.dependencies(context)
      end

      def value(context = {})
        cast(left.value(context)) * 0.01
      end

      def operator
        :%
      end

      def operator_spacing
        ""
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

      private

      def check_operands!(l, r)
        Dentaku::NumericLimits.check_power!(l, r)
      end
    end
  end
end
