require 'dentaku/token'

module Dentaku
  class TokenMatcher
    attr_reader :children, :categories, :values

    def initialize(categories = nil, values = nil, children = [])
      # store categories and values as hash to optimize key lookup, h/t @jan-mangs
      @categories = [categories].compact.flatten.each_with_object({}) { |c, h| h[c] = 1 }
      @values     = [values].compact.flatten.each_with_object({}) { |v, h| h[v] = 1 }
      @children   = children.compact
      @invert     = false

      @min = 1
      @max = 1
      @range = (@min..@max)
    end

    def |(other_matcher)
      self.class.new(:nomatch, :nomatch, leaf_matchers + other_matcher.leaf_matchers)
    end

    def invert
      @invert = ! @invert
      self
    end

    def ==(token)
      leaf_matcher? ? matches_token?(token) : any_child_matches_token?(token)
    end

    def match(token_stream, offset = 0)
      matched_tokens = []
      matched = false

      while self == token_stream[matched_tokens.length + offset] && matched_tokens.length < @max
        matched_tokens << token_stream[matched_tokens.length + offset]
      end

      if @range.cover?(matched_tokens.length)
        matched = true
      end

      [matched, matched_tokens]
    end

    def caret
      @caret = true
      self
    end

    def caret?
      @caret
    end

    def star
      @min = 0
      @max = Float::INFINITY
      @range = (@min..@max)
      self
    end

    def plus
      @max = Float::INFINITY
      @range = (@min..@max)
      self
    end

    def leaf_matcher?
      children.empty?
    end

    def leaf_matchers
      leaf_matcher? ? [self] : children
    end

    private

    def any_child_matches_token?(token)
      children.any? { |child| child == token }
    end

    def matches_token?(token)
      return false if token.nil?
      (category_match(token.category) && value_match(token.value)) ^ @invert
    end

    def category_match(category)
      @categories.empty? || @categories.key?(category)
    end

    def value_match(value)
      @values.empty? || @values.key?(value)
    end

    def self.datetime = new(:datetime)
    def self.numeric = new(:numeric)
    def self.string = new(:string)
    def self.logical = new(:logical)
    def self.value
      new(:datetime) | new(:numeric) | new(:string) | new(:logical)
    end

    def self.addsub = new(:operator, [:add, :subtract])
    def self.subtract = new(:operator, :subtract)
    def self.anchored_minus = new(:operator, :subtract).caret
    def self.muldiv = new(:operator, [:multiply, :divide])
    def self.pow = new(:operator, :pow)
    def self.mod = new(:operator, :mod)
    def self.combinator = new(:combinator)

    def self.comparator = new(:comparator)
    def self.comp_gt = new(:comparator, [:gt, :ge])
    def self.comp_lt = new(:comparator, [:lt, :le])

    def self.open = new(:grouping, :open)
    def self.close = new(:grouping, :close)
    def self.comma = new(:grouping, :comma)
    def self.non_group = new(:grouping).invert
    def self.non_group_star = new(:grouping).invert.star
    def self.non_close_plus = new(:grouping, :close).invert.plus
    def self.arguments = (value | comma).plus

    def self.function(name) = new(:function, name)

    def self.if = function(:if)
    def self.round = function(:round)
    def self.roundup = function(:roundup)
    def self.rounddown = function(:rounddown)
    def self.not = function(:not)
  end
end
