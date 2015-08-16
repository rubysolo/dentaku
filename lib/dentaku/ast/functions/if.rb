require_relative '../function'

module Dentaku
  module AST
    class If < Function
      attr_reader :predicate, :left, :right

      def initialize(predicate, left, right)
        @predicate = predicate
        @left      = left
        @right     = right
      end

      def value(context={})
        predicate.value(context) ? left.value(context) : right.value(context)
      end

      def type
        left.type
      end

      def dependencies(context={})
        # TODO : short-circuit?
        (predicate.dependencies(context) + left.dependencies(context) + right.dependencies(context)).uniq
      end
    end
  end
end

Dentaku::AST::Function.register_class(:if, Dentaku::AST::If)
