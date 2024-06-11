require_relative '../function'

module Dentaku
  module AST
    class If < Function
      attr_reader :predicate, :left, :right

      def self.min_param_count
        3
      end

      def self.max_param_count
        3
      end

      def initialize(predicate, left, right)
        @predicate = predicate
        @left      = left
        @right     = right
      end

      def args
        [predicate, left, right]
      end

      def value(context = {})
        predicate.value(context) ? left.value(context) : right.value(context)
      end

      def node_type
        :condition
      end

      def type
        left.type
      end

      def dependencies(context = {})
        predicate.value(context) ? left.dependencies(context) : right.dependencies(context)
      rescue Dentaku::Error, Dentaku::ArgumentError, Dentaku::ZeroDivisionError
        args.flat_map { |arg| arg.dependencies(context) }.uniq
      end
    end
  end
end

Dentaku::AST::Function.register_class(:if, Dentaku::AST::If)
