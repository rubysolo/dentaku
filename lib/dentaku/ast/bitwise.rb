require_relative './operation'
require_relative '../numeric_limits'

module Dentaku
  module AST
    class Bitwise < Operation
      def value(context = {})
        left_value = left.value(context)
        right_value = right.value(context)
        Dentaku::NumericLimits.check!(left_value)
        Dentaku::NumericLimits.check!(right_value)
        check_operands!(left_value, right_value)

        Dentaku::NumericLimits.check!(left_value.public_send(operator, right_value))
      rescue NoMethodError
        raise Dentaku::ArgumentError.for(:incompatible_type, actual: left_value, expected: Integer),
              "#{self.class} requires integer operands, but got #{left_value.class}"
      rescue TypeError
        raise Dentaku::ArgumentError.for(:incompatible_type, actual: right_value, expected: Integer),
              "#{self.class} requires integer operands, but got #{right_value.class}"
      end

      private

      # Hook for operators that can build a huge number from small operands
      def check_operands!(_left_value, _right_value); end
    end

    class BitwiseOr < Bitwise
      def operator
        :|
      end
    end

    class BitwiseAnd < Bitwise
      def operator
        :&
      end
    end

    class BitwiseShiftLeft < Bitwise
      def operator
        :<<
      end

      private

      def check_operands!(left_value, right_value)
        Dentaku::NumericLimits.check_shift!(left_value, right_value)
      end
    end

    class BitwiseShiftRight < Bitwise
      def operator
        :>>
      end
    end
  end
end
