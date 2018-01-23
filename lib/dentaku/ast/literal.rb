module Dentaku
  module AST
    class Literal < Node
      attr_reader :type

      def initialize(token)
        @token = token
        @value = token.value
        @type  = token.category
      end

      def value(*)
        @value
      end

      def dependencies(*)
        []
      end

      def accept(visitor)
        visitor.visit_literal(self)
      end

      def quoted
        @token.raw_value || value.to_s
      end
      alias_method :to_s, :quoted
    end
  end
end
