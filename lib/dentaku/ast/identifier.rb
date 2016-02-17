require_relative '../exceptions'

module Dentaku
  module AST
    class Identifier < Node
      attr_reader :identifier

      def initialize(token)
        @identifier = token.value.downcase
      end

      def value(context={})
        v = context.fetch(identifier) do
          raise UnboundVariableError.new([identifier])
        end

        case v
        when Node
          v.value(context)
        else
          v
        end
      end

      def dependencies(context={})
        context.has_key?(identifier) ? dependencies_of(context[identifier]) : [identifier]
      end

      private

      def dependencies_of(node)
        node.respond_to?(:dependencies) ? node.dependencies : []
      end
    end
  end
end
