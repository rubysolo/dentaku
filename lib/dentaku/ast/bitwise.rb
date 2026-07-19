require_relative './operation'

module Dentaku
  module AST
    class Bitwise < Operation
      def value(context = {})
        left_value = left.value(context)
        right_value = right.value(context)

        left_value.public_send(operator, right_value)
      rescue NoMethodError
        raise Dentaku::ArgumentError.for(:incompatible_type, actual: left_value, expected: Integer),
              "#{self.class} requires integer operands, but got #{left_value.class}"
      rescue TypeError
        raise Dentaku::ArgumentError.for(:incompatible_type, actual: right_value, expected: Integer),
              "#{self.class} requires integer operands, but got #{right_value.class}"
      end
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
    end

    class BitwiseShiftRight < Bitwise
      def operator
        :>>
      end
    end
  end
end
