module Dentaku
  module AST
    class Array
      def self.arity
      end

      def self.peek(*)
      end

      def initialize(*elements)
        @elements = *elements
      end

      def value(context = {})
        @elements.map { |el| el.value(context) }
      end

      def dependencies(context = {})
        @elements.flat_map { |el| el.dependencies(context) }
      end
    end
  end
end
