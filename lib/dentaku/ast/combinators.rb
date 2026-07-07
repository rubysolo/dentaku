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
        left_deps = left.dependencies(context)
        right_deps = right.dependencies(context)
        return [] if left_deps.empty? && decisive?(left.value(context))
        return [] if right_deps.empty? && decisive?(right.value(context))

        (left_deps + right_deps).uniq
      rescue Dentaku::Error
        super
      end

      def value(context = {})
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

      private

      def valid_node?(node)
        node && (node.dependencies.any? || node.type == :logical)
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
