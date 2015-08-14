module Dentaku
  module AST
    class Literal < Node
      attr_reader :type

      def initialize(token)
        @value = token.value
        @type  = token.category
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
