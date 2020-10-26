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
        collection = @args[0].value(context)
        pluck_path = @args[1].identifier

        collection.map { |h| h.transform_keys(&:to_s)[pluck_path] }
      end
    end
  end
end

Dentaku::AST::Function.register_class(:pluck, Dentaku::AST::Pluck)
