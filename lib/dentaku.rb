require "bigdecimal"
require "dentaku/calculator"
require "dentaku/version"

module Dentaku
  @enable_ast_caching = false
  @enable_dependency_order_caching = false

  def self.evaluate(expression, data={})
    calculator.evaluate(expression, data)
  end

  def self.enable_caching!
    enable_ast_cache!
    enable_dependency_order_cache!
  end

  def self.enable_ast_cache!
    @enable_ast_caching = true
  end

  def self.cache_ast?
    @enable_ast_caching
  end

  def self.enable_dependency_order_cache!
    @enable_dependency_order_caching = true
  end

  def self.cache_dependency_order?
    @enable_dependency_order_caching
  end

  private

  def self.calculator
    @calculator ||= Dentaku::Calculator.new
  end
end

def Dentaku(expression, data={})
  Dentaku.evaluate(expression, data)
end
