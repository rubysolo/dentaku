require 'dentaku/rules'

module Dentaku
  class Evaluator
    def evaluate(tokens)
      evaluate_token_stream(tokens).value
    end

    def evaluate_token_stream(tokens)
      while tokens.length > 1
        matched = false
        Rules.each do |pattern, evaluator|
          pos, match = find_rule_match(pattern, tokens)

          if pos
            tokens = evaluate_step(tokens, pos, match.length, evaluator)
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
      token_stream.insert start, *self.send(evaluator, *expr)
    end

    def find_rule_match(pattern, token_stream)
      position = 0

      while position <= token_stream.length
        matches = []
        matched = true

        pattern.each do |matcher|
          match = matcher.match(token_stream, position + matches.length)
          matched &&= match.matched?
          matches += match
        end

        return position, matches if matched
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
      when :pow      then Token.new(:numeric, l ** r)
      when :add      then Token.new(:numeric, l + r)
      when :subtract then Token.new(:numeric, l - r)
      when :multiply then Token.new(:numeric, l * r)
      when :divide   then Token.new(:numeric, divide(l, r))

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

    def divide(numerator, denominator)
      quotient, remainder = numerator.divmod(denominator)
      return quotient if remainder == 0
      numerator.to_f / denominator.to_f
    end

    def expand_range(left, oper1, middle, oper2, right)
      [left, oper1, middle, Token.new(:combinator, :and), middle, oper2, right]
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
      _, _, *tokens, _ = args

      input_tokens = tokens.take_while { |a| a.category != :grouping }
      input_value  = evaluate_token_stream(input_tokens).value
      places       = 0

      if places_token = tokens.drop_while { |a| a.category != :grouping }.last
        places = places_token.value
      end

      begin
        value = input_value.round(places)
      rescue ArgumentError
        value = (input * 10 ** places).round / (10 ** places).to_f
      end

      Token.new(:numeric, value)
    end

    def roundup(*args)
      _, _, *tokens, _ = args

      value = evaluate_token_stream(tokens).value
      Token.new(:numeric, value.ceil)
    end

    def rounddown(*args)
      _, _, *tokens, _ = args

      value = evaluate_token_stream(tokens).value
      Token.new(:numeric, value.floor)
    end

    def not(*args)
      Token.new(:logical, ! evaluate_token_stream(args[2..-2]).value)
    end
  end
end
