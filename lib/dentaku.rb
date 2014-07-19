require "bigdecimal"
require "dentaku/calculator"
require "dentaku/version"

module Dentaku
  def self.evaluate(expression, data={})
    calculator.evaluate(expression, data)
  end

  class UnboundVariableError < Exception
  end

  private

  def self.calculator
    @calculator ||= Dentaku::Calculator.new
  end
end

def Dentaku(expression, data={})
  Dentaku.evaluate(expression, data)
end
