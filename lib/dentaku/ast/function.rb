require_relative 'node'

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
        registry.fetch(function_name(name)) {
          fail ParseError, "Undefined function #{ name }"
        }
      end

      def self.register(name, type, implementation)
        function = Class.new(self) do
          def self.implementation=(impl)
            @implementation = impl
          end

          def self.implementation
            @implementation
          end

          def self.type=(type)
            @type = type
          end

          def self.type
            @type
          end

          def value(context={})
            args = @args.map { |a| a.value(context) }
            self.class.implementation.call(*args)
          end

          def type
            self.class.type
          end
        end

        function_class = name.to_s.capitalize
        Dentaku::AST.send(:remove_const, function_class) if Dentaku::AST.const_defined?(function_class)
        Dentaku::AST.const_set(function_class, function)

        function.implementation = implementation
        function.type = type

        registry[function_name(name)] = function
      end

      def self.register_class(name, function_class)
        registry[function_name(name)] = function_class
      end

      private

      def self.function_name(name)
        name.to_s.downcase
      end

      def self.registry
        @registry ||= {}
      end
    end
  end
end
