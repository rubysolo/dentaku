module Dentaku
  module AST
    class CustomFunction < Function
      def self.name=(name)
        @name = name
      end

      def self.name
        @name
      end

      def name
        self.class.name
      end

      # To keep everything functional, variable argument functions should
      # have "nil" arity
      def self.arity
        @arity ||= implementation.arity < 0 ? nil : implementation.arity
      end

      def arity
        self.class.arity
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

      def value(context={})
        args = @args.map { |a| a.value(context) }
        self.class.implementation.call(*args)
      end

      def type
        self.class.type
      end
    end
  end
end
