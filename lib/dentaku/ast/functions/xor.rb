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
            function_name: 'XOR', expected: 1.., actual: 0
          )
        end

        # exclusive OR of all arguments: true when an odd number are true, so
        # XOR(a, b, c) == XOR(XOR(a, b), c)
        true_arg_count = @args.count do |arg|
          case arg.value(context)
          when TrueClass
            true
          when FalseClass, nil
            false
          else
            raise Dentaku::ArgumentError.for(
              :incompatible_type,
              function_name: 'XOR', expected: :logical, actual: arg
            )
          end
        end
        true_arg_count.odd?
      end
    end
  end
end

Dentaku::AST::Function.register_class(:xor, Dentaku::AST::Xor)
