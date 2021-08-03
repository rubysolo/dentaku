require_relative '../function'
require_relative '../../exceptions'

module Dentaku
  module AST
    class Enum < Function
      def self.min_param_count
        3
      end

      def self.max_param_count
        3
      end

      def dependencies(context = {})
        validate_identifier(@args[1])

        collection      = @args[0]
        item_identifier = @args[1].identifier
        expression      = @args[2]

        collection_deps = collection.dependencies(context)
        expression_deps = (expression&.dependencies(context) || []).reject do |i|
          i == item_identifier || i.start_with?("#{item_identifier}.")
        end

        collection_deps + expression_deps
      end

      def validate_identifier(arg, message = "#{name}() requires second argument to be an identifier")
        unless arg.is_a?(Identifier)
          raise ArgumentError.for(:incompatible_type, value: arg, for: Identifier), message
        end
      end
    end
  end
end
