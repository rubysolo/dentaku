require "dentaku/calculator"
require "dentaku/version"

module Dentaku
  def self.[](expression, data={})
    calculator.evaluate(expression, data)
  end

  private

  def self.calculator
    @calculator ||= Dentaku::Calculator.new
  end
end
