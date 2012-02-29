require 'dentaku/token'

module Dentaku
  class TokenMatcher
    def initialize(categories=nil, values=nil)
      @categories = [categories].compact.flatten
      @values     = [values].compact.flatten
      @invert     = false

      @min = 1
      @max = 1
    end

    def invert
      @invert = ! @invert
      self
    end

    def ==(token)
      (category_match(token.category) && value_match(token.value)) ^ @invert
    end

    def match(token_stream, offset=0)
      matched_tokens = []

      while self == token_stream[matched_tokens.length + offset] && matched_tokens.length < @max
        matched_tokens << token_stream[matched_tokens.length + offset]
      end

      if (@min..@max).include? matched_tokens.length
        def matched_tokens.matched?() true end
      else
        def matched_tokens.matched?() false end
      end

      matched_tokens
    end

    def star
      @min = 0
      @max = 1.0/0
      self
    end

    def plus
      @max = 1.0/0
      self
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

