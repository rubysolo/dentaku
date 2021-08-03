require_relative '../function'
require_relative '../../exceptions'

module Dentaku
  module AST
    class Enumerable < Function
      def self.min_param_count
        3
      end

      def self.max_param_count
        3
      end

      def deferred_args
        [1, 2]
      end

      def dependencies(context = {})
        collection      = @args[0]
        item_identifier = @args[1].identifier
        expression      = @args[2]

        collection.dependencies + expression.dependencies - [item_identifier]
      end
    end
  end
end
