require_relative './case/case_conditional'
require_relative './case/case_when'
require_relative './case/case_then'
require_relative './case/case_switch_variable'
require_relative './case/case_else'

module Dentaku
  module AST
    class Case < Node
      def initialize(*nodes)
        @switch = nodes.shift

        unless @switch.is_a?(AST::CaseSwitchVariable)
          raise 'Case missing switch variable'
        end

        @conditions = nodes

        @else = @conditions.pop if @conditions.last.is_a?(AST::CaseElse)

        @conditions.each do |condition|
          unless condition.is_a?(AST::CaseConditional)
            raise "#{condition} is not a CaseConditional"
          end
        end
      end

      def value(context={})
        switch_value = @switch.value(context)
        @conditions.each do |condition|
          if condition.when.value(context) == switch_value
            return condition.then.value(context)
          end
        end

        if @else
          return @else.value(context)
        else
          raise "No block matched the switch value '#{switch_value}'"
        end
      end

      def dependencies(context={})
        # TODO: should short-circuit
        @switch.dependencies(context) +
          @conditions.flat_map do |condition|
            condition.dependencies(context)
          end
      end
    end
  end
end
