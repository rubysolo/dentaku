require_relative '../function'
require_relative '../../exceptions'

module Dentaku
  module AST
    class Xor < Function
      def self.min_param_count
        1
      end

      def self.max_param_count
        Float::INFINITY
      end

      def value(context = {})
        if @args.empty?
          raise Dentaku::ArgumentError.for(
            :too_few_arguments,
            function_name: 'XOR()', at_least: 1, given: 0
          ), 'XOR() requires at least one argument'
        end

        true_arg_count = 0
        @args.each do |arg|
          case arg.value(context)
          when TrueClass
            true_arg_count += 1
            break if true_arg_count > 1
          when FalseClass, nil
            next
          else
            raise Dentaku::ArgumentError.for(
              :incompatible_type,
              function_name: 'XOR()', expect: :logical, actual: arg.class
            ), 'XOR() requires arguments to be logical expressions'
          end
        end
        true_arg_count == 1
      end
    end
  end
end

Dentaku::AST::Function.register_class(:xor, Dentaku::AST::Xor)
