require_relative './enumerable'

module Dentaku
  module AST
    class Map < Enumerable
      def value(context = {})
        collection      = @args[0].value(context)
        item_identifier = @args[1].identifier
        expression      = @args[2]

        collection.map do |item_value|
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

Dentaku::AST::Function.register_class(:map, Dentaku::AST::Map)
