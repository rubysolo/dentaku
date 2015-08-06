module Dentaku
  module AST
    class And < Operation
      def value(context={})
        left.value(context) && right.value(context)
      end
    end

    class Or < Operation
      def value(context={})
        left.value(context) || right.value(context)
      end
    end
  end
end
