require_relative './enumerable'

module Dentaku
  module AST
    class Any < Enumerable
      def value(context = {})
        collection      = @args[0].value(context)
        item_identifier = @args[1].identifier
        expression      = @args[2]

        Array(collection).any? do |item_value|
          expression.value(
            context.merge(
              FlatHash.from_hash_with_intermediates(item_identifier => item_value)
            )
          )
        end
      end
    end
  end
end

Dentaku::AST::Function.register_class(:any, Dentaku::AST::Any)
