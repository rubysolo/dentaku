require_relative "../exceptions"
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

        unless structure.respond_to?(:[]) && !structure.is_a?(::Numeric)
          raise Dentaku::ArgumentError.for(:incompatible_type, value: structure),
                "#{self.class} requires an indexable structure, but got #{structure.class}"
        end

        begin
          structure[index]
        rescue ::TypeError => e
          raise Dentaku::ArgumentError.for(:incompatible_type, value: index), e.message
        end
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
