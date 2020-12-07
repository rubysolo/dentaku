require_relative "./node"

module Dentaku
  module AST
    class Array < Node
      def self.arity
      end

      def self.min_param_count
        0
      end

      def self.max_param_count
        Float::INFINITY
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

      def type
        nil
      end
    end
  end
end
