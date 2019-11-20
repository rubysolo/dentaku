require_relative './case/case_conditional'
require_relative './case/case_when'
require_relative './case/case_then'
require_relative './case/case_switch_variable'
require_relative './case/case_else'
require 'dentaku/exceptions'

module Dentaku
  module AST
    class Case < Node
      def self.min_param_count
        2
      end

      def self.max_param_count
        Float::INFINITY
      end

      def initialize(*nodes)
        @switch = nodes.shift

        unless @switch.is_a?(AST::CaseSwitchVariable)
          raise ParseError.for(:node_invalid), 'Case missing switch variable'
        end

        @conditions = nodes

        @else = nil
        @else = @conditions.pop if @conditions.last.is_a?(AST::CaseElse)

        @conditions.each do |condition|
          unless condition.is_a?(AST::CaseConditional)
            raise ParseError.for(:node_invalid), "#{condition} is not a CaseConditional"
          end
        end
      end

      def value(context = {})
        switch_value = @switch.value(context)
        @conditions.each do |condition|
          if condition.when.value(context) == switch_value
            return condition.then.value(context)
          end
        end

        if @else
          return @else.value(context)
        else
          raise ArgumentError.for(:invalid_value), "No block matched the switch value '#{switch_value}'"
        end
      end

      def dependencies(context = {})
        # TODO: should short-circuit
        switch_dependencies(context) +
        condition_dependencies(context) +
        else_dependencies(context)
      end

      private

      def switch_dependencies(context = {})
        @switch.dependencies(context)
      end

      def condition_dependencies(context = {})
        @conditions.flat_map { |condition| condition.dependencies(context) }
      end

      def else_dependencies(context = {})
        @else ? @else.dependencies(context) : []
      end
    end
  end
end
