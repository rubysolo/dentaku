require 'dentaku/token'
require 'dentaku/token_matcher'

module Dentaku
  class Evaluator
    # tokens
    T_NUMERIC    = TokenMatcher.new(:numeric)
    T_STRING     = TokenMatcher.new(:string)
    T_ADDSUB     = TokenMatcher.new(:operator, [:add, :subtract])
    T_MULDIV     = TokenMatcher.new(:operator, [:multiply, :divide])
    T_COMPARATOR = TokenMatcher.new(:comparator)
    T_OPEN       = TokenMatcher.new(:grouping, :open)
    T_CLOSE      = TokenMatcher.new(:grouping, :close)
    T_COMMA      = TokenMatcher.new(:grouping, :comma)
    T_NON_GROUP  = TokenMatcher.new(:grouping).invert
    T_LOGICAL    = TokenMatcher.new(:logical)
    T_COMBINATOR = TokenMatcher.new(:combinator)
    T_IF         = TokenMatcher.new(:function, :if)
    T_ROUND      = TokenMatcher.new(:function, :round)

    # patterns
    P_GROUP      = [T_OPEN,    T_NON_GROUP,  T_CLOSE]
    P_MATH_ADD   = [T_NUMERIC, T_ADDSUB,     T_NUMERIC]
    P_MATH_MUL   = [T_NUMERIC, T_MULDIV,     T_NUMERIC]
    P_NUM_COMP   = [T_NUMERIC, T_COMPARATOR, T_NUMERIC]
    P_STR_COMP   = [T_STRING,  T_COMPARATOR, T_STRING]
    P_COMBINE    = [T_LOGICAL, T_COMBINATOR, T_LOGICAL]

    P_IF         = [T_IF, T_OPEN, T_NON_GROUP, T_COMMA, T_NON_GROUP, T_COMMA, T_NON_GROUP, T_CLOSE]
    P_ROUND_ONE  = [T_ROUND, T_OPEN, T_NUMERIC, T_CLOSE]
    P_ROUND_TWO  = [T_ROUND, T_OPEN, T_NUMERIC, T_COMMA, T_NUMERIC, T_CLOSE]

    RULES = [
      [P_IF,         :if],
      [P_ROUND_ONE,  :round],
      [P_ROUND_TWO,  :round],

      [P_GROUP,      :evaluate_group],
      [P_MATH_MUL,   :apply],
      [P_MATH_ADD,   :apply],
      [P_NUM_COMP,   :apply],
      [P_STR_COMP,   :apply],
      [P_COMBINE,    :apply]
    ]

    def evaluate(tokens)
      evaluate_token_stream(tokens).value
    end

    def evaluate_token_stream(tokens)
      while tokens.length > 1
        matched = false
        RULES.each do |pattern, evaluator|
          if pos = find_rule_match(pattern, tokens)
            tokens = evaluate_step(tokens, pos, pattern.length, evaluator)
            matched = true
            break
          end
        end

        raise "no rule matched #{ tokens.map(&:category).inspect }" unless matched
      end

      tokens << Token.new(:numeric, 0) if tokens.empty?

      tokens.first
    end

    def evaluate_step(token_stream, start, length, evaluator)
      expr = token_stream.slice!(start, length)
      token_stream.insert start, self.send(evaluator, *expr)
    end

    def find_rule_match(pattern, token_stream)
      position = 0
      while position <= token_stream.length - pattern.length
        substream = token_stream.slice(position, pattern.length)
        return position if pattern == substream
        position += 1
      end
      nil
    end

    def evaluate_group(*args)
      evaluate_token_stream(args[1..-2])
    end

    def apply(lvalue, operator, rvalue)
      l = lvalue.value
      r = rvalue.value

      case operator.value
      when :add      then Token.new(:numeric, l + r)
      when :subtract then Token.new(:numeric, l - r)
      when :multiply then Token.new(:numeric, l * r)
      when :divide   then Token.new(:numeric, l / r)

      when :le       then Token.new(:logical, l <= r)
      when :ge       then Token.new(:logical, l >= r)
      when :lt       then Token.new(:logical, l <  r)
      when :gt       then Token.new(:logical, l >  r)
      when :ne       then Token.new(:logical, l != r)
      when :eq       then Token.new(:logical, l == r)

      when :and      then Token.new(:logical, l && r)
      when :or       then Token.new(:logical, l || r)

      else
        raise "unknown comparator '#{ comparator }'"
      end
    end

    def if(*args)
      _, open, condition, _, true_value, _, false_value, close = args

      if condition.value
        true_value
      else
        false_value
      end
    end

    def round(*args)
      function = args.shift
      open     = args.shift
      input    = args.shift.value
      places   = 0

      if args.length > 1
        comma  = args.shift
        places = args.shift.value
      end

      Token.new(:numeric, input.round(places))
    end
  end
end
