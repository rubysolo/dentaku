module Dentaku
  module AST
    class Node
      def self.precedence
        0
      end

      def self.arity
        nil
      end

      def dependencies(context={})
        []
      end
    end
  end
end
