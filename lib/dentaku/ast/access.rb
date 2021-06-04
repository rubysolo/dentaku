require_relative "./node"

module Dentaku
  module AST
    class Access < Node
      def self.arity
        2
      end

      def self.min_param_count
        arity
      end

      def self.max_param_count
        arity
      end

      def self.peek(*)
      end

      def initialize(data_structure, index)
        @structure = data_structure
        @index = index
      end

      def value(context = {})
        structure = @structure.value(context)
        index = @index.value(context)
        structure[index]
      end

      def dependencies(context = {})
        @structure.dependencies(context) + @index.dependencies(context)
      end

      def type
        nil
      end
    end
  end
end
