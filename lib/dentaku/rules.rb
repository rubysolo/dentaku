require 'dentaku/external_function'
require 'dentaku/token'
require 'dentaku/token_matcher'

module Dentaku
  class Rules
    def self.core_rules
      [
        [ p(:if),           :if             ],
        [ p(:round),        :round          ],
        [ p(:roundup),      :round_int      ],
        [ p(:rounddown),    :round_int      ],
        [ p(:not),          :not            ],

        [ p(:group),        :evaluate_group ],
        [ p(:start_neg),    :negate         ],
        [ p(:math_pow),     :apply          ],
        [ p(:math_neg_pow), :pow_negate     ],
        [ p(:math_mod),     :apply          ],
        [ p(:math_mul),     :apply          ],
        [ p(:math_neg_mul), :mul_negate     ],
        [ p(:math_add),     :apply          ],
        [ p(:percentage),   :percentage     ],
        [ p(:negation),     :negate         ],
        [ p(:range_asc),    :expand_range   ],
        [ p(:range_desc),   :expand_range   ],
        [ p(:num_comp),     :apply          ],
        [ p(:str_comp),     :apply          ],
        [ p(:combine),      :apply          ]
      ]
    end

    def self.each
      @rules ||= core_rules
      @rules.each { |r| yield r }
    end

    def self.refresh
      @rules ||= core_rules
      @p_values ||= {}
      @p_categories ||= {}

      @rules.each do |pattern, _|
        @p_values[pattern] = pattern.map{ |matcher| matcher.values }.reduce{ |a, e| a.merge(e) }.keys
        @p_categories[pattern] = pattern.map{ |matcher| matcher.categories }.reduce{ |a, e| a.merge(e) }.keys
      end
    end

    def self.filter(tokens)
      @cache ||= {}
      categories = tokens.map { |token| token.category }.uniq
      values = tokens.map { |token| token.value.is_a?(Numeric) ? 0 : token.value }
      values.select! { |token| ![:fopen, :close].include?(token) }
      select(categories, values)
    end

    def self.select(categories, values)
      return @cache[categories + values] if @cache.has_key?(categories + values)
      @cache[categories + values] = @rules.select do |pattern, _|
        categories_intersection = @p_categories[pattern] & categories
        values_intersection = @p_values[pattern] & values
        categories_intersection.length > 0 && (values_intersection.length > 0 || @p_values[pattern].empty?)
      end
    end


    def self.add_function(f)
      ext = ExternalFunction.new(f[:name], f[:type], f[:signature], f[:body])

      @rules ||= core_rules
      @funcs ||= {}

      ## rules need to be added to the beginning of @rules for precedence
      @rules.unshift [
        [
          TokenMatcher.send(ext.name),
          t(:fopen),
          *pattern(*ext.tokens),
          t(:close)
        ],
        ext.name
      ]

      refresh
      @funcs[ext.name] = ext
    end

    def self.func(name)
      @funcs ||= {}
      @funcs.fetch(name)
    end

    def self.t(name)
      @matchers ||= generate_matchers
      @matchers.fetch(name)
    end

    def self.generate_matchers
      [
        :numeric, :string, :addsub, :subtract, :muldiv, :pow, :mod,
        :comparator, :comp_gt, :comp_lt, :fopen, :open, :close, :comma,
        :non_close_plus, :non_group, :non_group_star, :arguments,
        :logical, :combinator, :if, :round, :roundup, :rounddown, :not,
        :anchored_minus, :math_neg_pow, :math_neg_mul
      ].each_with_object({}) do |name, matchers|
        matchers[name] = TokenMatcher.send(name)
      end
    end

    def self.p(name)
      @patterns ||= {
        group:        pattern(:open,     :non_group_star, :close),
        math_add:     pattern(:numeric,  :addsub,         :numeric),
        math_mul:     pattern(:numeric,  :muldiv,         :numeric),
        math_neg_mul: pattern(:numeric,  :muldiv,         :subtract, :numeric),
        math_pow:     pattern(:numeric,  :pow,            :numeric),
        math_neg_pow: pattern(:numeric,  :pow,            :subtract, :numeric),
        math_mod:     pattern(:numeric,  :mod,            :numeric),
        negation:     pattern(:subtract, :numeric),
        start_neg:    pattern(:anchored_minus, :numeric),
        percentage:   pattern(:numeric,  :mod),
        range_asc:    pattern(:numeric,  :comp_lt,        :numeric,  :comp_lt, :numeric),
        range_desc:   pattern(:numeric,  :comp_gt,        :numeric,  :comp_gt, :numeric),
        num_comp:     pattern(:numeric,  :comparator,     :numeric),
        str_comp:     pattern(:string,   :comparator,     :string),
        combine:      pattern(:logical,  :combinator,     :logical),

        if:           func_pattern(:if,        :non_group,      :comma, :non_group, :comma, :non_group),
        round:        func_pattern(:round,     :arguments),
        roundup:      func_pattern(:roundup,   :arguments),
        rounddown:    func_pattern(:rounddown, :arguments),
        not:          func_pattern(:not,       :arguments)
      }

      @patterns[name]
    end

    def self.pattern(*symbols)
      symbols.map { |s| t(s) }
    end

    def self.func_pattern(func, *tokens)
      pattern(func, :fopen, *tokens, :close)
    end
  end
end
