require_relative '../function'

module Dentaku
  module AST
    class Count < Function
      def self.min_param_count
        0
      end

      def self.max_param_count
        Float::INFINITY
      end

      def value(context = {})
        if @args.length == 1
          first_arg = @args[0].value(context)
          return first_arg.length if first_arg.respond_to?(:length)
        end

        @args.length
      end
    end
  end
end

Dentaku::AST::Function.register_class(:count, Dentaku::AST::Count)
