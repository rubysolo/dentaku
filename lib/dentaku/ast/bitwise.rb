require_relative './operation'

module Dentaku
  module AST
    class BitwiseOr < Operation
      def value(context = {})
        left.value(context) | right.value(context)
      end

      def operator
        :|
      end
    end

    class BitwiseAnd < Operation
      def value(context = {})
        left.value(context) & right.value(context)
      end

      def operator
        :&
      end
    end

    class BitwiseShiftLeft < Operation
      def value(context = {})
        left.value(context) << right.value(context)
      end

      def operator
        :<<
      end
    end

    class BitwiseShiftRight < Operation
      def value(context = {})
        left.value(context) >> right.value(context)
      end

      def operator
        :>>
      end
    end
  end
end
