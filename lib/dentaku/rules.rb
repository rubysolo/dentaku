require 'dentaku/token'
require 'dentaku/token_matcher'

module Dentaku
  class Rules
    # tokens
    T_NUMERIC    = TokenMatcher.new(:numeric)
    T_STRING     = TokenMatcher.new(:string)
    T_ADDSUB     = TokenMatcher.new(:operator, [:add, :subtract])
    T_MULDIV     = TokenMatcher.new(:operator, [:multiply, :divide])
    T_POW        = TokenMatcher.new(:operator, :pow)
    T_COMPARATOR = TokenMatcher.new(:comparator)
    T_COMP_GT    = TokenMatcher.new(:comparator, [:gt, :ge])
    T_COMP_LT    = TokenMatcher.new(:comparator, [:lt, :le])
    T_OPEN       = TokenMatcher.new(:grouping, :open)
    T_CLOSE      = TokenMatcher.new(:grouping, :close)
    T_COMMA      = TokenMatcher.new(:grouping, :comma)
    T_NON_GROUP  = TokenMatcher.new(:grouping).invert
    T_LOGICAL    = TokenMatcher.new(:logical)
    T_COMBINATOR = TokenMatcher.new(:combinator)
    T_IF         = TokenMatcher.new(:function, :if)
    T_ROUND      = TokenMatcher.new(:function, :round)
    T_ROUNDUP    = TokenMatcher.new(:function, :roundup)
    T_ROUNDDOWN  = TokenMatcher.new(:function, :rounddown)
    T_NOT        = TokenMatcher.new(:function, :not)

    T_NON_GROUP_STAR = TokenMatcher.new(:grouping).invert.star

    # patterns
    P_GROUP      = [T_OPEN,    T_NON_GROUP_STAR, T_CLOSE]
    P_MATH_ADD   = [T_NUMERIC, T_ADDSUB,         T_NUMERIC]
    P_MATH_MUL   = [T_NUMERIC, T_MULDIV,         T_NUMERIC]
    P_MATH_POW   = [T_NUMERIC, T_POW,            T_NUMERIC]
    P_RANGE_ASC  = [T_NUMERIC, T_COMP_LT,        T_NUMERIC, T_COMP_LT, T_NUMERIC]
    P_RANGE_DESC = [T_NUMERIC, T_COMP_GT,        T_NUMERIC, T_COMP_GT, T_NUMERIC]
    P_NUM_COMP   = [T_NUMERIC, T_COMPARATOR,     T_NUMERIC]
    P_STR_COMP   = [T_STRING,  T_COMPARATOR,     T_STRING]
    P_COMBINE    = [T_LOGICAL, T_COMBINATOR,     T_LOGICAL]

    P_IF         = [T_IF, T_OPEN, T_NON_GROUP, T_COMMA, T_NON_GROUP, T_COMMA, T_NON_GROUP, T_CLOSE]
    P_ROUND_ONE  = [T_ROUND, T_OPEN, T_NON_GROUP_STAR, T_CLOSE]
    P_ROUND_TWO  = [T_ROUND, T_OPEN, T_NON_GROUP_STAR, T_COMMA, T_NUMERIC, T_CLOSE]
    P_ROUNDUP    = [T_ROUNDUP, T_OPEN, T_NON_GROUP_STAR, T_CLOSE]
    P_ROUNDDOWN  = [T_ROUNDDOWN, T_OPEN, T_NON_GROUP_STAR, T_CLOSE]
    P_NOT        = [T_NOT, T_OPEN, T_NON_GROUP_STAR, T_CLOSE]

    def self.each
      @rules ||= [
        [P_IF,         :if],
        [P_ROUND_ONE,  :round],
        [P_ROUND_TWO,  :round],
        [P_ROUNDUP,    :round_int],
        [P_ROUNDDOWN,  :round_int],
        [P_NOT,        :not],

        [P_GROUP,      :evaluate_group],
        [P_MATH_POW,   :apply],
        [P_MATH_MUL,   :apply],
        [P_MATH_ADD,   :apply],
        [P_RANGE_ASC,  :expand_range],
        [P_RANGE_DESC, :expand_range],
        [P_NUM_COMP,   :apply],
        [P_STR_COMP,   :apply],
        [P_COMBINE,    :apply]
      ]

      @rules.each { |r| yield r }
    end
  end
end
