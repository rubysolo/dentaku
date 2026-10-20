module Dentaku
  module AST
    class Negation < Arithmetic
      attr_reader :node

      def initialize(node)
        @node = node

        unless valid_node?(node)
          raise NodeError.new(:numeric, node.type, :node),
                "#{self.class} requires numeric operands"
        end
      end

      def operator
        :*
      end

      def value(context = {})
        cast(@node.value(context)) * -1
      end

      def type
        :numeric
      end

      def self.arity
        1
      end

      def self.right_associative?
        true
      end

      def self.prefix?
        true
      end

      def self.precedence
        40
      end

      def dependencies(context = {})
        @node.dependencies(context)
      end

      def accept(visitor)
        visitor.visit_negation(self)
      end

      private

      # bypasses Operation's binary initialize, so left/right are unset
      def compute_pure?
        @node.pure?
      end

      # static dependency check: this runs at parse time, and evaluating
      # short-circuit guards here would execute user functions (#197)
      def valid_node?(node)
        node && (node.dependencies(Node::STATIC_CONTEXT).any? || node.type == :numeric)
      end
    end
  end
end
