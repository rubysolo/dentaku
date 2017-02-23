module Dentaku
  module AST
    class FunctionRegistry < Hash
      def get(name)
        name = function_name(name)
        return self[name] if has_key?(name)
        return default[name] if default.has_key?(name)
        fail ParseError, "Undefined function #{ name }"
      end

      def register(name, type, implementation)
        function = Class.new(Function) do
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

        function_class = name.to_s.capitalize.gsub('!', '_')
        Dentaku::AST.send(:remove_const, function_class) if Dentaku::AST.const_defined?(function_class, false)
        Dentaku::AST.const_set(function_class, function)

        function.implementation = implementation
        function.type = type

        self[function_name(name)] = function
      end

      def register_class(name, function_class)
        self[function_name(name)] = function_class
      end

      def default
        self.class.default
      end

      def self.default
        Dentaku::AST::Function.registry
      end

      private

      def function_name(name)
        name.to_s.downcase
      end
    end
  end
end
