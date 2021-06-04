# import all functions from Ruby's Math module
require_relative '../function'

module Dentaku
  module AST
    class RubyMath < Function
      def self.[](method)
        klass = Class.new(self)
        klass.implement(method)
        klass
      end

      def self.implement(method)
        @name = method
        @implementation = Math.method(method)
      end

      def self.name
        @name
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

      def self.call(*args)
        @implementation.call(*args)
      end

      def value(context = {})
        args = @args.flatten.map { |a| Dentaku::AST::Function.numeric(a.value(context)) }
        self.class.call(*args)
      end

      ARRAY_RETURN_TYPES = [:frexp, :lgamma].freeze

      def type
        ARRAY_RETURN_TYPES.include?(@name) ? :array : :numeric
      end
    end
  end
end

Math.methods(false).each do |method|
  Dentaku::AST::Function.register_class(method, Dentaku::AST::RubyMath[method])
end
