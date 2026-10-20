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

      # A short-circuit probe that raises tells us nothing about which operands are
      # referenced, so fall back to the union of both sides. It has to be the union we
      # already computed rather than `super`: `super` re-derives it by walking both
      # subtrees again, and because the probe raises at every level of a chain, each
      # level would walk its subtree twice -- making analysis exponential in the
      # length of the chain.
      def dependencies(context = {})
        return super if static_mode?(context)

        left_deps = left.dependencies(context)
        right_deps = right.dependencies(context)

        if left_deps.empty? && left.pure?
          begin
            return [] if decisive?(left.value(context))
          rescue Dentaku::Error
            return (left_deps + right_deps).uniq
          end
        end

        if right_deps.empty? && right.pure?
          begin
            return [] if decisive?(right.value(context))
          rescue Dentaku::Error
            return (left_deps + right_deps).uniq
          end
        end

        (left_deps + right_deps).uniq
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

    # the XOR operator; the XOR function is AST::Xor
    class ExclusiveOr < Combinator
      def operator
        :xor
      end

      # both operands are always needed, so nothing short-circuits
      def value(context = {})
        logical(left.value(context)) ^ logical(right.value(context))
      end

      private

      def decisive?(_operand_value)
        false
      end

      # null counts as false, as in the XOR function
      def logical(operand_value)
        case operand_value
        when true, false then operand_value
        when nil then false
        else
          raise Dentaku::ArgumentError.for(:incompatible_type, actual: operand_value, expected: :logical),
                "#{self.class} requires logical operands"
        end
      end
    end

    # the prefix NOT operator (or `!`); the NOT function is AST::Function::Not
    class Not < Operation
      def self.arity
        1
      end

      def self.prefix?
        true
      end

      def self.right_associative?
        true
      end

      # looser than comparisons, so `NOT a > 5` is `NOT (a > 5)`, and tighter
      # than AND, OR and XOR, so `NOT a AND b` is `(NOT a) AND b`
      def self.precedence
        3
      end

      def initialize(node)
        @right = node

        unless valid_node?(node)
          raise NodeError.new(:logical, node.type, :node),
                "#{self.class} requires a logical operand"
        end
      end

      def operator
        :not
      end

      def type
        :logical
      end

      def value(context = {})
        !right.value(context)
      end

      def dependencies(context = {})
        right.dependencies(context)
      end

      private

      # static dependency check: this runs at parse time, and evaluating
      # short-circuit guards here would execute user functions (#197)
      def valid_node?(node)
        node && (node.dependencies(Node::STATIC_CONTEXT).any? || node.type == :logical)
      end
    end
  end
end
