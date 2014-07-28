require "bigdecimal"
require "dentaku/calculator"
require "dentaku/version"

module Dentaku
  def self.evaluate(expression, data={})
    calculator.evaluate(expression, data)
  end

  class UnboundVariableError < StandardError
    attr_reader :unbound_variables

    def initialize(unbound_variables)
      @unbound_variables = unbound_variables
    end
  end

  private

  def self.calculator
    @calculator ||= Dentaku::Calculator.new
  end
end

def Dentaku(expression, data={})
  Dentaku.evaluate(expression, data)
end
