require_relative './operation'

module Dentaku
  module AST
    class BitwiseOr < Operation
      def value(context = {})
        left.value(context) | right.value(context)
      end
    end

    class BitwiseAnd < Operation
      def value(context = {})
        left.value(context) & right.value(context)
      end
    end
  end
end
