module Dentaku
  module AST
    class Numeric < Node
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
