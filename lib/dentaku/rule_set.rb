require 'dentaku/external_function'

module Dentaku
  class RuleSet
    def initialize
      self.custom_rules = []
      self.custom_functions = {}
    end

    def rules
      custom_rules + core_rules
    end

    def each
      rules.each { |r| yield r }
    end

    def add_function(function)
      fn = ExternalFunction.new(function[:name], function[:type], function[:signature], function[:body])

      custom_rules.push [
        function_token_matchers(fn.name, *fn.tokens),
        fn.name
      ]

      custom_functions[fn.name] = fn
      clear_cache
    end

    def filter(tokens)
      categories = tokens.map(&:category).uniq
      values     = tokens.map { |token| token.value.is_a?(Numeric) ? 0 : token.value }
                         .reject { |token| [:fopen, :close].include?(token) }
      select(categories, values)
    end

    def select(categories, values)
      @cache ||= {}
      return @cache[categories + values] if @cache.has_key?(categories + values)

      @cache[categories + values] = rules.select do |pattern, _|
        categories_intersection = matcher_categories[pattern] & categories
        values_intersection     = matcher_values[pattern] & values
        categories_intersection.length > 0 && (values_intersection.length > 0 || matcher_values[pattern].empty?)
      end
    end

    def function(name)
      custom_functions.fetch(name)
    end

    private
    attr_accessor :custom_rules, :custom_functions

    def matcher_categories
      @matcher_categories ||= rules.each_with_object({}) do |(pattern, _), h|
        h[pattern] = pattern.map(&:categories).reduce { |a,b| a.merge(b) }.keys
      end
    end

    def matcher_values
      @matcher_values ||= rules.each_with_object({}) do |(pattern, _), h|
        h[pattern] = pattern.map(&:values).reduce { |a,b| a.merge(b) }.keys
      end
    end

    def clear_cache
      @cache = nil
      @matcher_categories = nil
      @matcher_values = nil
    end

    def core_rules
      @core_rules ||= [
        [ pattern(:if),           :if             ],
        [ pattern(:round),        :round          ],
        [ pattern(:roundup),      :round_int      ],
        [ pattern(:rounddown),    :round_int      ],
        [ pattern(:not),          :not            ],

        [ pattern(:group),        :evaluate_group ],
        [ pattern(:start_neg),    :negate         ],
        [ pattern(:math_pow),     :apply          ],
        [ pattern(:math_neg_pow), :pow_negate     ],
        [ pattern(:math_mod),     :apply          ],
        [ pattern(:math_mul),     :apply          ],
        [ pattern(:math_neg_mul), :mul_negate     ],
        [ pattern(:math_add),     :apply          ],
        [ pattern(:percentage),   :percentage     ],
        [ pattern(:negation),     :negate         ],
        [ pattern(:range_asc),    :expand_range   ],
        [ pattern(:range_desc),   :expand_range   ],
        [ pattern(:num_comp),     :apply          ],
        [ pattern(:str_comp),     :apply          ],
        [ pattern(:combine),      :apply          ]
      ]
    end

    def pattern(name)
      @patterns ||= {
        group:        token_matchers(:open,     :non_group_star, :close),
        math_add:     token_matchers(:numeric,  :addsub,         :numeric),
        math_mul:     token_matchers(:numeric,  :muldiv,         :numeric),
        math_neg_mul: token_matchers(:numeric,  :muldiv,         :subtract, :numeric),
        math_pow:     token_matchers(:numeric,  :pow,            :numeric),
        math_neg_pow: token_matchers(:numeric,  :pow,            :subtract, :numeric),
        math_mod:     token_matchers(:numeric,  :mod,            :numeric),
        negation:     token_matchers(:subtract, :numeric),
        start_neg:    token_matchers(:anchored_minus, :numeric),
        percentage:   token_matchers(:numeric,  :mod),
        range_asc:    token_matchers(:numeric,  :comp_lt,        :numeric,  :comp_lt, :numeric),
        range_desc:   token_matchers(:numeric,  :comp_gt,        :numeric,  :comp_gt, :numeric),
        num_comp:     token_matchers(:numeric,  :comparator,     :numeric),
        str_comp:     token_matchers(:string,   :comparator,     :string),
        combine:      token_matchers(:logical,  :combinator,     :logical),

        if:           function_token_matchers(:if,        :non_group,      :comma, :non_group, :comma, :non_group),
        round:        function_token_matchers(:round,     :arguments),
        roundup:      function_token_matchers(:roundup,   :arguments),
        rounddown:    function_token_matchers(:rounddown, :arguments),
        not:          function_token_matchers(:not,       :arguments)
      }

      @patterns[name]
    end

    def token_matchers(*symbols)
      symbols.map { |s| matcher(s) }
    end

    def function_token_matchers(function_name, *symbols)
      token_matchers(:fopen, *symbols, :close).unshift(
        TokenMatcher.send(function_name)
      )
    end

    def matcher(symbol)
      @matchers ||= [
        :numeric, :string, :addsub, :subtract, :muldiv, :pow, :mod,
        :comparator, :comp_gt, :comp_lt, :fopen, :open, :close, :comma,
        :non_close_plus, :non_group, :non_group_star, :arguments,
        :logical, :combinator, :if, :round, :roundup, :rounddown, :not,
        :anchored_minus, :math_neg_pow, :math_neg_mul
      ].each_with_object({}) do |name, matchers|
        matchers[name] = TokenMatcher.send(name)
      end

      @matchers.fetch(symbol) do
        raise "Unknown token symbol #{ symbol }"
      end
    end
  end
end
