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
        collection = Array(@args[0].value(context))
        if !collection.all? { |elem| elem.is_a?(Hash) }
          raise ArgumentError.for(:incompatible_type, value: collection),
                'PLUCK() requires first argument to be an array of hashes'
        end

        pluck_path = @args[1]
        if !pluck_path.is_a?(Identifier)
          raise ArgumentError.for(:incompatible_type, value: pluck_path, for: Identifier),
                'PLUCK() requires second argument to be an identifier'
        end
        pluck_path = pluck_path.identifier

        collection.map { |h| h.transform_keys(&:to_s)[pluck_path] }
      end
    end
  end
end

Dentaku::AST::Function.register_class(:pluck, Dentaku::AST::Pluck)
