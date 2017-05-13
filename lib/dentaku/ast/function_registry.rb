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
        function = Class.new(Dentaku::AST::CustomFunction)

        function.name = name.to_sym
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
