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

          def self.min_param_count
            @implementation.parameters.select { |type, _name| type == :req }.count
          end

          def self.max_param_count
            @implementation.parameters.select { |type, _name| type == :rest }.any? ? Float::INFINITY : @implementation.parameters.count
          end

          def value(context = {})
            args = @args.map { |a| a.value(context) }
            self.class.implementation.call(*args)
          end

          def type
            self.class.type
          end
        end

        define_class(name, function)

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

      def normalize_name(function_name)
        function_name.to_s.capitalize.gsub(/\W/, '_')
      end

      def define_class(function_name, function)
        class_name = normalize_name(function_name)
        return if Dentaku::AST::Function.const_defined?(class_name)

        Dentaku::AST::Function.const_set(class_name, function)
      end
    end
  end
end
