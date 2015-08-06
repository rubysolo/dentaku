require_relative '../exceptions'

module Dentaku
  module AST
    class Identifier < Node
      attr_reader :identifier

      def initialize(token)
        @identifier = token.value.downcase
      end

      def value(context={})
        v = context[identifier]
        case v
        when Node
          v.value
        when NilClass
          raise UnboundVariableError.new([identifier])
        else
          v
        end
      end

      def dependencies(context={})
        context.has_key?(identifier) ? [] : [identifier]
      end
    end
  end
end
