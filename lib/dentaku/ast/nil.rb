module Dentaku
  module AST
    class Nil < Node
      def initialize(*args)
      end

      def value(*)
        nil
      end
    end
  end
end
