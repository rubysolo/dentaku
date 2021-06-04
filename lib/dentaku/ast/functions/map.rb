require_relative '../function'
require_relative '../../exceptions'

module Dentaku
  module AST
    class Map < Function
      def self.min_param_count
        3
      end

      def self.max_param_count
        3
      end

      def deferred_args
        [1, 2]
      end

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
