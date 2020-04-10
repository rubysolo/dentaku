require "bigdecimal"
require "dentaku/calculator"
require "dentaku/version"

module Dentaku
  @cache_ast = false
  @cache_dependency_order = false
  @short_circuit_evaluation = true
  @aliases = {}

  def self.evaluate(expression, data = {})
    calculator.evaluate(expression, data)
  end

  def self.evaluate!(expression, data = {})
    calculator.evaluate!(expression, data)
  end

  def self.enable_caching!
    enable_ast_cache!
    enable_dependency_order_cache!
  end

  def self.enable_ast_cache!
    @cache_ast = true
  end

  def self.cache_ast?
    @cache_ast
  end

  def self.enable_dependency_order_cache!
    @cache_dependency_order = true
  end

  def self.cache_dependency_order?
    @cache_dependency_order
  end

  def self.disable_short_circuit_evaluation!
    @short_circuit_evaluation = false
  end

  def self.short_circuit_evaluation?
    @short_circuit_evaluation
  end

  def self.aliases
    @aliases
  end

  def self.aliases=(hash)
    @aliases = hash
  end

  def self.calculator
    @calculator ||= Dentaku::Calculator.new
  end
end

def Dentaku(expression, data = {})
  Dentaku.evaluate(expression, data)
end

def Dentaku!(expression, data = {})
  Dentaku.evaluate!(expression, data)
end
