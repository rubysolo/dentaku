require 'dentaku/exceptions'

module Dentaku
  module AST
    class CaseConditional < Node
      attr_reader :when,
                  :then

      def self.min_param_count
        2
      end

      def self.max_param_count
        2
      end

      def initialize(when_statement, then_statement)
        @when = when_statement
        unless @when.is_a?(AST::CaseWhen)
          raise ParseError.for(:node_invalid), 'Expected first argument to be a CaseWhen'
        end

        @then = then_statement
        unless @then.is_a?(AST::CaseThen)
          raise ParseError.for(:node_invalid), 'Expected second argument to be a CaseThen'
        end
      end

      def dependencies(context = {})
        @when.dependencies(context) + @then.dependencies(context)
      end
    end
  end
end
