require_relative './operation'

module Dentaku
  module AST
    class Bitwise < Operation
      def value(context = {})
        left_value = left.value(context)
        right_value = right.value(context)

        left_value.public_send(operator, right_value)
      rescue NoMethodError => e
        raise Dentaku::ArgumentError.for(:invalid_operator, value: left_value, for: left_value.class)
      rescue TypeError => e
        raise Dentaku::ArgumentError.for(:invalid_operator, value: right_value, for: right_value.class)
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
