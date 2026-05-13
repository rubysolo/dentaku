require_relative 'node'
require_relative 'function_registry'

module Dentaku
  module AST
    class Function < Node
      attr_reader :args

      # @return [Integer] with the number of significant decimal digits to use.
      DIG = Float::DIG + 1

      def initialize(*args)
        @args = args
      end

      def accept(visitor)
        visitor.visit_function(self)
      end

      def dependencies(context = {})
        @args.each_with_index
             .flat_map { |a, _| a.dependencies(context) }
      end

      def self.get(name)
        registry.get(name)
      end

      def self.register(name, type, implementation)
        registry.register(name, type, implementation)
      end

      def self.register_class(name, function_class)
        registry.register_class(name, function_class)
      end

      def self.registry
        @registry ||= FunctionRegistry.new
      end
    end
  end
end
