require_relative './enum'
require_relative '../../exceptions'

module Dentaku
  module AST
    class Map < Enum
      def value(context = {})
        validate_identifier(@args[1])

        collection      = Array(@args[0].value(context))
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
