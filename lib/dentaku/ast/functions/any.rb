require_relative './enum'

module Dentaku
  module AST
    class Any < Enum
      def value(context = {})
        collection      = Array(@args[0].value(context))
        item_identifier = @args[1].identifier
        expression      = @args[2]

        collection.any? do |item_value|
          mapped_value(expression, context, item_identifier => item_value)
        end
      end
    end
  end
end

Dentaku::AST::Function.register_class(:any, Dentaku::AST::Any)
