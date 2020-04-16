require_relative './operation'
require_relative '../date_arithmetic'
require 'bigdecimal'
require 'bigdecimal/util'

module Dentaku
  module AST
    class Arithmetic < Operation
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
        l = cast(left.value(context))
        r = cast(right.value(context))
        begin
          l.public_send(operator, r)
        rescue ::TypeError => e
          # Right cannot be converted to a suitable type for left. e.g. [] + 1
          raise Dentaku::ArgumentError.for(:incompatible_type, value: r, for: l.class), e.message
        end
      end

      private

      def cast(val, prefer_integer = true)
        validate_value(val)
        numeric(val, prefer_integer)
      end

      def numeric(val, prefer_integer)
        v = BigDecimal(val, Float::DIG + 1)
        v = v.to_i if prefer_integer && v.frac.zero?
        v
      rescue ::TypeError
        # If we got a TypeError BigDecimal or to_i failed;
        # let value through so ruby things like Time - integer work
        val
      end

      def valid_node?(node)
        node && (node.type == :numeric || node.dependencies.any?)
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
        if left.type == :datetime
          Dentaku::DateArithmetic.new(left.value(context)).add(right.value(context))
        else
          super
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
        if left.type == :datetime
          Dentaku::DateArithmetic.new(left.value(context)).sub(right.value(context))
        else
          super
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
        r = cast(right.value(context), false)
        raise Dentaku::ZeroDivisionError if r.zero?

        cast(cast(left.value(context)) / r)
      end

      def self.precedence
        20
      end
    end

    class Modulo < Arithmetic
      def self.arity
        @arity
      end

      def self.peek(input)
        @arity = 1
        @arity = 2 if input.length > 1
      end

      def initialize(left, right = nil)
        if right
          @left  = left
          @right = right
        else
          @right = left
        end

        unless valid_left?
          raise NodeError.new(%i[numeric nil], left.type, :left),
                "#{self.class} requires numeric operands or nil"
        end
        unless valid_right?
          raise NodeError.new(:numeric, right.type, :right),
                "#{self.class} requires numeric operands"
        end
      end

      def dependencies(context = {})
        if percent?
          @right.dependencies(context)
        else
          super
        end
      end

      def percent?
        left.nil?
      end

      def value(context = {})
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
