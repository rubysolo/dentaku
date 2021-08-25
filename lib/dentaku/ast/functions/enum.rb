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

      def deferred_args
        [1, 2]
      end

      def validate_identifier(arg, message = "#{name}() requires second argument to be an identifier")
        unless arg.is_a?(Identifier)
          raise ArgumentError.for(:incompatible_type, value: arg, for: Identifier), message
        end
      end
    end
  end
end
