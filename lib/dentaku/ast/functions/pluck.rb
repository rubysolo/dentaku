require_relative './enum'
require_relative '../../exceptions'

module Dentaku
  module AST
    class Pluck < Enum
      def self.min_param_count
        2
      end

      def self.max_param_count
        3
      end

      def value(context = {})
        collection = Array(@args[0].value(context))

        unless collection.all? { |elem| elem.is_a?(Hash) }
          raise ArgumentError.for(:incompatible_type, value: collection),
                'PLUCK() requires first argument to be an array of hashes'
        end

        pluck_path = @args[1].identifier
        default    = @args[2]

        collection.map { |h|
          h.transform_keys(&:to_s).fetch(pluck_path, default&.value(context))
        }
      end
    end
  end
end

Dentaku::AST::Function.register_class(:pluck, Dentaku::AST::Pluck)
