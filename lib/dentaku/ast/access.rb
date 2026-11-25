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

      # nil-safe: accessing into NULL is NULL
      def value(context = {})
        structure = @structure.value(context)
        return nil if structure.nil?

        read(structure, @index.value(context))
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

      private

      def read(structure, index)
        unless structure.respond_to?(:[]) && !structure.is_a?(::Numeric)
          raise Dentaku::ArgumentError.for(:incompatible_type, actual: structure),
                "#{self.class} requires an indexable structure, but got #{structure.class}"
        end

        structure[index]
      rescue ::TypeError => e
        raise Dentaku::ArgumentError.for(:incompatible_type, actual: index), e.message
      end

      def compute_pure?
        @structure.pure? && @index.pure?
      end
    end
  end
end
