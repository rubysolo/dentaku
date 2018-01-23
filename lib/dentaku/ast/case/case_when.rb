module Dentaku
  module AST
    class CaseWhen < Operation
      attr_reader :node

      def self.arity
        1
      end

      def initialize(node)
        @node = node
      end

      def value(context = {})
        @node.value(context)
      end

      def dependencies(context = {})
        @node.dependencies(context)
      end

      def accept(visitor)
        visitor.visit_when(self)
      end

      def to_s
        'WHEN'
      end
    end
  end
end
