require 'dentaku/external_function'
require 'dentaku/token'
require 'dentaku/token_matcher'

module Dentaku
  class Rules
    def self.core_rules
      [
        [ p(:if),         :if             ],
        [ p(:round),      :round          ],
        [ p(:roundup),    :round_int      ],
        [ p(:rounddown),  :round_int      ],
        [ p(:not),        :not            ],

        [ p(:group),      :evaluate_group ],
        [ p(:math_pow),   :apply          ],
        [ p(:math_mod),   :apply          ],
        [ p(:math_mul),   :apply          ],
        [ p(:math_add),   :apply          ],
        [ p(:percentage), :percentage     ],
        [ p(:negation),   :negate         ],
        [ p(:range_asc),  :expand_range   ],
        [ p(:range_desc), :expand_range   ],
        [ p(:num_comp),   :apply          ],
        [ p(:str_comp),   :apply          ],
        [ p(:combine),    :apply          ]
      ]
    end

    def self.each
      @rules ||= core_rules
      @rules.each { |r| yield r }
    end

    def self.add_function(f)
      ext = ExternalFunction.new(f[:name], f[:type], f[:signature], f[:body])

      @rules ||= core_rules
      @funcs ||= {}

      ## rules need to be added to the beginning of @rules for precedence
      @rules.unshift [
        [
          TokenMatcher.send(ext.name),
          t(:open),
          *pattern(*ext.tokens),
          t(:close)
        ],
        ext.name
      ]
      @funcs[ext.name] = ext
    end

    def self.func(name)
      @funcs ||= {}
      @funcs[name]
    end

    def self.t(name)
      @matchers ||= generate_matchers
      @matchers[name]
    end

    def self.generate_matchers
      [
        :numeric, :string, :addsub, :subtract, :muldiv, :pow, :mod,
        :comparator, :comp_gt, :comp_lt,
        :open, :close, :comma,
        :non_close_plus, :non_group, :non_group_star,
        :logical, :combinator,
        :if, :round, :roundup, :rounddown, :not
      ].each_with_object({}) do |name, matchers|
        matchers[name] = TokenMatcher.send(name)
      end
    end

    def self.p(name)
      @patterns ||= {
        group:      pattern(:open,     :non_group_star, :close),
        math_add:   pattern(:numeric,  :addsub,         :numeric),
        math_mul:   pattern(:numeric,  :muldiv,         :numeric),
        math_pow:   pattern(:numeric,  :pow,            :numeric),
        math_mod:   pattern(:numeric,  :mod,            :numeric),
        negation:   pattern(:subtract, :numeric),
        percentage: pattern(:numeric,  :mod),
        range_asc:  pattern(:numeric,  :comp_lt,        :numeric,  :comp_lt, :numeric),
        range_desc: pattern(:numeric,  :comp_gt,        :numeric,  :comp_gt, :numeric),
        num_comp:   pattern(:numeric,  :comparator,     :numeric),
        str_comp:   pattern(:string,   :comparator,     :string),
        combine:    pattern(:logical,  :combinator,     :logical),

        if:         func_pattern(:if,        :non_group,      :comma, :non_group, :comma, :non_group),
        round:      func_pattern(:round,     :non_close_plus),
        roundup:    func_pattern(:roundup,   :non_close_plus),
        rounddown:  func_pattern(:rounddown, :non_close_plus),
        not:        func_pattern(:not,       :non_close_plus)
      }

      @patterns[name]
    end

    def self.pattern(*symbols)
      symbols.map { |s| t(s) }
    end

    def self.func_pattern(func, *tokens)
      pattern(func, :open, *tokens, :close)
    end
  end
end
