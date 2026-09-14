require_relative './operation'
require 'dentaku/exceptions'

module Dentaku
  module AST
    class Combinator < Operation
      def initialize(*)
        super

        unless valid_node?(left)
          raise NodeError.new(:logical, left.type, :left),
                "#{self.class} requires logical operands"
        end
        unless valid_node?(right)
          raise NodeError.new(:logical, right.type, :right),
                "#{self.class} requires logical operands"
        end
      end

      def type
        :logical
      end

      def dependencies(context = {})
        return super if static_mode?(context)

        left_deps = left.dependencies(context)
        right_deps = right.dependencies(context)

        begin
          if left_deps.empty? && left.pure?
            left_value = left.value(context)
            return settled(context, left_value) if decisive?(left_value)
            # left is bound but does not decide, so the result is right's value
            # whenever right is bound as well
            return settled(context, right.value(context)) if right_deps.empty? && right.pure?
          elsif right_deps.empty? && right.pure?
            right_value = right.value(context)
            return (left.pure? ? settled(context, right_value) : []) if decisive?(right_value)
          end
        rescue Dentaku::Error
          # a probe that raises cannot prune anything; the union below is what
          # Operation#dependencies would recompute from the same two walks
        end

        (left_deps + right_deps).uniq
      end

      def value(context = {})
        remembered(context) do
          left_value = begin
            left.value(context)
          rescue UnboundVariableError => unbound
            unbound
          end

          unless left_value.is_a?(UnboundVariableError)
            return left_value if decisive?(left_value)

            return right.value(context)
          end

          # The left operand is unbound; the right operand can still decide the
          # result on its own. If it does not, the left value was needed.
          right_value = right.value(context)
          raise left_value unless decisive?(right_value)

          right_value
        end
      end

      private

      # static dependency check: this runs at parse time, and evaluating
      # short-circuit guards here would execute user functions (#197)
      def valid_node?(node)
        node && (node.dependencies(Node::STATIC_CONTEXT).any? || node.type == :logical)
      end

      # whether a single operand with this value already determines the
      # result, regardless of the other operand
      def decisive?(operand_value)
        raise NotImplementedError
      end
    end

    class And < Combinator
      def operator
        :and
      end

      private

      def decisive?(operand_value)
        !operand_value
      end
    end

    class Or < Combinator
      def operator
        :or
      end

      private

      def decisive?(operand_value)
        !!operand_value
      end
    end
  end
end
