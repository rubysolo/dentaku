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

      def initialize(*args)
        super
        validate_identifier(@args[1])
      end

      def dependencies(context = {})
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
        raise ParseError.for(:node_invalid), message unless arg.is_a?(Identifier)
      end
    end
  end
end
