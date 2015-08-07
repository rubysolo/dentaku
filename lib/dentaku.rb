require "bigdecimal"
require "dentaku/calculator"
require "dentaku/version"

module Dentaku
  def self.evaluate(expression, data={})
    calculator.evaluate(expression, data)
  end

  def self.enable_ast_cache!
    @enable_ast_caching = true
  end

  def self.cache_ast?
    @enable_ast_caching
  end

  private

  def self.calculator
    @calculator ||= Dentaku::Calculator.new
  end
end

def Dentaku(expression, data={})
  Dentaku.evaluate(expression, data)
end
