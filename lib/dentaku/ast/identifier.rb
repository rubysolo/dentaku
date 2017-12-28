require_relative '../exceptions'
require 'dentaku/string_casing'

module Dentaku
  module AST
    class Identifier < Node
      include StringCasing
      attr_reader :identifier, :case_sensitive

      def initialize(token, options = {})
        @case_sensitive = options.fetch(:case_sensitive, false)
        @identifier = standardize_case(token.value)
      end

      def value(context = {})
        v = context.fetch(identifier) do
          raise UnboundVariableError.new([identifier]),
                "no value provided for variables: #{identifier}"
        end

        case v
        when Node
          v.value(context)
        else
          v
        end
      end

      def dependencies(context = {})
        context.key?(identifier) ? dependencies_of(context[identifier]) : [identifier]
      end

      def accept(visitor)
        visitor.visit_identifier(self)
      end

      private

      def dependencies_of(node)
        node.respond_to?(:dependencies) ? node.dependencies : []
      end
    end
  end
end
