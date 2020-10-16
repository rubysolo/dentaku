require_relative 'node'
require_relative 'function_registry'

module Dentaku
  module AST
    class Function < Node
      # @return [Integer] with the number of significant decimal digits to use.
      DIG = Float::DIG + 1

      def initialize(*args)
        @args = args
      end

      def dependencies(context = {})
        deferred = deferred_args
        @args.each_with_index
             .reject { |_, i| deferred.include? i }
             .flat_map { |a, _| a.dependencies(context) }
      end

      # override if your function implementation needs to defer evaluation of
      # any arguments
      def deferred_args
        []
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

        if value.is_a?(::String)
          number = value[/\A-?\d*\.?\d+\z/]
          return number.include?('.') ? BigDecimal(number, DIG) : number.to_i if number
        end

        raise Dentaku::ArgumentError.for(:incompatible_type, value: value, for: Numeric),
          "'#{value || value.class}' is not coercible to numeric"
      end
    end
  end
end
