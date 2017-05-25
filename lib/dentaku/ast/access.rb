module Dentaku
  module AST
    class Access
      def self.arity
        2
      end

      def initialize(data_structure, index)
        @structure = data_structure
        @index = index
      end

      def value(context={})
        structure = @structure.value(context)
        index = @index.value(context)
        structure[index]
      end

      def dependencies(context={})
        @structure.dependencies(context) + @index.dependencies(context)
      end
    end
  end
end
