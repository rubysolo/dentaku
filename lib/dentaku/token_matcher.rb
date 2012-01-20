require 'dentaku/token'

module Dentaku
  class TokenMatcher
    def initialize(categories=nil, values=nil)
      @categories = [categories].compact.flatten
      @values     = [values].compact.flatten
      @invert     = false
    end

    def invert
      @invert = ! @invert
      self
    end

    def ==(token)
      (category_match(token.category) && value_match(token.value)) ^ @invert
    end

    private

    def category_match(category)
      @categories.empty? || @categories.include?(category)
    end

    def value_match(value)
      @values.empty? || @values.include?(value)
    end
  end
end

