require_relative './operation'

module Dentaku
  module AST
    class Bitwise < Operation
      def value(context = {})
        left_value = left.value(context)
        right_value = right.value(context)

        left_value.public_send(operator, right_value)
      rescue NoMethodError => e
        raise Dentaku::ArgumentError.for(:invalid_operator, actual: left_value, expected: Integer)
      rescue TypeError => e
        raise Dentaku::ArgumentError.for(:invalid_operator, actual: right_value, expected: Integer)
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
