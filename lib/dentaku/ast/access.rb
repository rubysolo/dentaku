require_relative "./node"

module Dentaku
  module AST
    class Access < Node
      attr_reader :structure, :index

      def self.arity
        2
      end

      def self.min_param_count
        arity
      end

      def self.max_param_count
        arity
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

      def accept(visitor)
        visitor.visit_access(self)
      end
    end
  end
end
