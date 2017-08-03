module Dentaku
  module AST
    class FunctionRegistry < Hash
      def get(name)
        name = function_name(name)
        return self[name] if has_key?(name)
        return default[name] if default.has_key?(name)
        nil
      end

      def register(name, type, implementation)
        function = Class.new(Function) do
          def self.name=(name)
            @name = name
          end

          def self.name
            @name
          end

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

          def self.arity
            @implementation.arity < 0 ? nil : @implementation.arity
          end

          def value(context={})
            args = @args.map { |a| a.value(context) }
            self.class.implementation.call(*args)
          end

          def type
            self.class.type
          end
        end

        function.name = name
        function.type = type
        function.implementation = implementation

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
