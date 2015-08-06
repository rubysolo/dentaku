module Dentaku
  module AST
    class Nil < Node
      def value(*)
        nil
      end
    end
  end
end
