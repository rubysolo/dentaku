require_relative '../function'

module Dentaku
  module AST
    class Duration < Function
      def self.min_param_count
        1
      end

      def self.max_param_count
        1
      end

      class Value
        attr_reader :value, :unit

        def initialize(value, unit)
          @value = value
          @unit = validate_unit(unit)
        end

        def validate_unit(unit)
          case unit.downcase
          when /years?/ then :year
          when /months?/ then :month
          when /days?/ then :day
          else
            raise Dentaku::ArgumentError.for(:incompatible_type, value: unit, for: Duration),
              "'#{unit || unit.class}' is not a valid duration unit"
          end
        end
      end

      def type
        :duration
      end

      def value(context = {})
        value_node, unit_node = *@args
        Value.new(value_node.value(context), unit_node.identifier)
      end

      def dependencies(context = {})
        value_node = @args.first
        value_node.dependencies(context)
      end
    end
  end
end

Dentaku::AST::Function.register_class(:duration, Dentaku::AST::Duration)
