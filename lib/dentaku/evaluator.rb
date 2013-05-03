require 'dentaku/rules'
require 'dentaku/binary_operation'

module Dentaku
  class Evaluator
    def evaluate(tokens)
      evaluate_token_stream(tokens).value
    end

    def evaluate_token_stream(tokens)
      while tokens.length > 1
        matched, tokens = match_rule_pattern(tokens)
        raise "no rule matched #{ tokens.map(&:category).inspect }" unless matched
      end

      tokens << Token.new(:numeric, 0) if tokens.empty?

      tokens.first
    end

    def match_rule_pattern(tokens)
      matched = false
      Rules.each do |pattern, evaluator|
        pos, match = find_rule_match(pattern, tokens)

        if pos
          tokens = evaluate_step(tokens, pos, match.length, evaluator)
          matched = true
          break
        end
      end

      [matched, tokens]
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

    def evaluate_step(token_stream, start, length, evaluator)
      expr = token_stream.slice!(start, length)
      token_stream.insert start, *self.send(evaluator, *expr)
    end

    def evaluate_group(*args)
      evaluate_token_stream(args[1..-2])
    end

    def apply(lvalue, operator, rvalue)
      operation = BinaryOperation.new(lvalue.value, rvalue.value)
      raise "unknown operation #{ operator.value }" unless operation.respond_to?(operator.value)
      Token.new(*operation.send(operator.value))
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
      _, _, *tokens = args
      tokens.pop

      input_tokens, places_tokens = tokens.chunk { |t| t.category == :grouping }.
                                          reject { |flag, tokens| flag }.
                                             map { |flag, tokens| tokens }

      input_value  = evaluate_token_stream(input_tokens).value
      places       = places_tokens ? evaluate_token_stream(places_tokens).value : 0

      value = input_value.round(places)

      Token.new(:numeric, value)
    end

    def round_int(*args)
      function, _, *tokens = args
      tokens.pop

      value = evaluate_token_stream(tokens).value
      rounded = if function.value == :roundup
        value.ceil
      else
        value.floor
      end

      Token.new(:numeric, rounded)
    end

    def not(*args)
      Token.new(:logical, ! evaluate_token_stream(args[2..-2]).value)
    end
  end
end
