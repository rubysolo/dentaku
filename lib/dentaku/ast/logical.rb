module Dentaku
  module AST
    class Logical < Node
      def initialize(token)
        @value = token.value
      end

      def value(*)
        @value
      end

      def dependencies(*)
        []
      end
    end
  end
end
