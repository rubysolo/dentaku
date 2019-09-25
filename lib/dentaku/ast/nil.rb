module Dentaku
  module AST
    class Nil < Node
      def value(*)
        nil
      end

      def accept(visitor)
        visitor.visit_nil(self)
      end
    end
  end
end
