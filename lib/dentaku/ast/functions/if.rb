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
        remembered(context) do
          predicate.value(context) ? left.value(context) : right.value(context)
        end
      end

      def node_type
        :condition
      end

      def type
        left.type
      end

      def dependencies(context = {})
        return all_arg_dependencies(context) if static_mode?(context) || !predicate.pure?

        branch = predicate.value(context) ? left : right
        branch_deps = branch.dependencies(context)
        settle_from(context, branch) if branch_deps.empty? && branch.pure?
        branch_deps
      rescue Dentaku::Error
        all_arg_dependencies(context)
      end

      private

      def all_arg_dependencies(context)
        args.flat_map { |arg| arg.dependencies(context) }.uniq
      end
    end
  end
end

Dentaku::AST::Function.register_class(:if, Dentaku::AST::If)
