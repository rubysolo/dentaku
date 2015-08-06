module Dentaku
  module AST
    class String < Node
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
