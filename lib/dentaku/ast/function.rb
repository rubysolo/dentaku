require_relative 'node'
require_relative 'function_registry'

module Dentaku
  module AST
    class Function < Node
      def initialize(*args)
        @args = args
      end

      def dependencies(context={})
        @args.flat_map { |a| a.dependencies(context) }
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

      # @return [Numeric] where possible it returns an Integer otherwise a BigDecimal.
      # An Exception will be raised if a value is passed that cannot be cast to a Number.
      def self.numeric(value)
        return value if value.is_a?(::Numeric)

        decimal = BigDecimal.new(value, Float::DIG + 1)
        decimal.frac.zero? ? decimal.to_i : decimal
      end
    end
  end
end
