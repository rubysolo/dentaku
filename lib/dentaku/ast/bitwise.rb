require_relative './operation'

module Dentaku
  module AST
    class BitwiseOr < Operation
      def value(context = {})
        left.value(context, true) | right.value(context, true)
      end

      def operator
        :|
      end
    end

    class BitwiseAnd < Operation
      def value(context = {})
        left.value(context, true) & right.value(context, true)
      end

      def operator
        :&
      end
    end
  end
end
