require_relative './operation'

module Dentaku
  module AST
    class Exponentiation < Operation
      def value(context={})
        left.value(context) ** right.value(context)
      end

      def self.precedence
        30
      end
    end
  end
end
