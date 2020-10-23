require_relative '../function'
require_relative '../../exceptions'

module Dentaku
  module AST
    class Pluck < Function
      def self.min_param_count
        2
      end

      def self.max_param_count
        2
      end

      def deferred_args
        [1]
      end

      def value(context = {})
        collection    = @args[0].value(context)
        property_name = @args[1].identifier

        collection.map do |item|
          item[property_name.to_sym] || item[property_name]
        end
      end
    end
  end
end

Dentaku::AST::Function.register_class(:pluck, Dentaku::AST::Pluck)
