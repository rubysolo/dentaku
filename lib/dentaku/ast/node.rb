module Dentaku
  module AST
    class Node
      def self.precedence
        0
      end

      def self.arity
        nil
      end

      def self.peek(*)
      end

      def dependencies(context = {})
        []
      end

      def type
        nil
      end
    end
  end
end
