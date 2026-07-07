module Dentaku
  module TokenMatchers
    def self.token_matchers(*symbols)
      symbols.map { |s| matcher(s) }
    end

    def self.function_token_matchers(function_name, *symbols)
      token_matchers(:open, *symbols, :close).unshift(
        TokenMatcher.function(function_name)
      )
    end

    def self.matcher(symbol)
      @matchers ||= [
        :datetime, :numeric, :string, :addsub, :subtract, :muldiv, :pow, :mod,
        :comparator, :comp_gt, :comp_lt, :open, :close, :comma,
        :non_close_plus, :non_group, :non_group_star, :arguments,
        :logical, :combinator, :if, :round, :roundup, :rounddown, :not,
        :anchored_minus
      ].each_with_object({}) do |name, matchers|
        matchers[name] = TokenMatcher.public_send(name)
      end

      @matchers.fetch(symbol) do
        raise "Unknown token symbol #{ symbol }"
      end
    end
  end
end
