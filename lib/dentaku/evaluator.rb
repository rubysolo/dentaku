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
        raise "no rule matched {{#{ inspect_tokens(tokens) }}}" unless matched
      end

      tokens << Token.new(:numeric, 0) if tokens.empty?

      tokens.first
    end

    def inspect_tokens(tokens)
      tokens.map { |t| t.to_s }.join(' ')
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
          _matched, match = matcher.match(token_stream, position + matches.length)
          matched &&= _matched
          matches += match
        end

        return position, matches if matched
        position += 1
      end

      nil
    end

    def evaluate_step(token_stream, start, length, evaluator)
      substream = token_stream.slice!(start, length)

      if self.respond_to?(evaluator)
        token_stream.insert start, *self.send(evaluator, *substream)
      else
        result = user_defined_function(evaluator, substream)
        token_stream.insert start, result
      end
    end

    def user_defined_function(evaluator, tokens)
      function = Rules.func(evaluator)
      raise "unknown function '#{ evaluator }'" unless function

      arguments = extract_arguments_from_function_call(tokens).map { |t| t.value }
      return_value = function.body.call(*arguments)
      Token.new(function.type, return_value)
    end

    def extract_arguments_from_function_call(tokens)
      _function_name, _open, *args_and_commas, _close = tokens
      args_and_commas.reject { |token| token.is?(:grouping) }
    end

    def evaluate_group(*args)
      evaluate_token_stream(args[1..-2])
    end

    def apply(lvalue, operator, rvalue)
      operation = BinaryOperation.new(lvalue.value, rvalue.value)
      raise "unknown operation #{ operator.value }" unless operation.respond_to?(operator.value)
      Token.new(*operation.send(operator.value))
    end

    def negate(_, token)
      Token.new(token.category, token.value * -1)
    end

    def percentage(token, _)
      Token.new(token.category, token.value / 100.0)
    end

    def expand_range(left, oper1, middle, oper2, right)
      [left, oper1, middle, Token.new(:combinator, :and), middle, oper2, right]
    end

    def if(*args)
      _if, _open, condition, _, true_value, _, false_value, _close = args

      if condition.value
        true_value
      else
        false_value
      end
    end

    def round(*args)
      _, _, *tokens, _ = args

      input_tokens, places_tokens = tokens.chunk { |t| t.category == :grouping }.
                                          reject { |flag, tokens| flag }.
                                             map { |flag, tokens| tokens }

      input_value  = evaluate_token_stream(input_tokens).value
      places       = places_tokens ? evaluate_token_stream(places_tokens).value : 0

      value = input_value.round(places)

      Token.new(:numeric, value)
    end

    def round_int(*args)
      function, _, *tokens, _ = args

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
