require 'dentaku/token'

module Dentaku
  class TokenMatcher
    def initialize(categories=nil, values=nil)
      @categories = [categories].compact.flatten
      @values     = [values].compact.flatten
      @invert     = false

      @categories_hash = Hash[@categories.map { |cat| [cat, 1] }]
      @values_hash = Hash[@values.map { |value| [value, 1] }]

      @min = 1
      @max = 1
      @range = (@min..@max)
    end

    def invert
      @invert = ! @invert
      self
    end

    def ==(token)
      return false if token.nil?
      (category_match(token.category) && value_match(token.value)) ^ @invert
    end

    def match(token_stream, offset=0)
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

    private

    def category_match(category)
      @categories_hash.empty? || @categories_hash.key?(category)
    end

    def value_match(value)
      @values.empty? || @values_hash.key?(value)
    end

    def self.numeric;        new(:numeric);                        end
    def self.string;         new(:string);                         end
    def self.addsub;         new(:operator, [:add, :subtract]);    end
    def self.subtract;       new(:operator, :subtract);            end
    def self.muldiv;         new(:operator, [:multiply, :divide]); end
    def self.pow;            new(:operator, :pow);                 end
    def self.mod;            new(:operator, :mod);                 end
    def self.comparator;     new(:comparator);                     end
    def self.comp_gt;        new(:comparator, [:gt, :ge]);         end
    def self.comp_lt;        new(:comparator, [:lt, :le]);         end
    def self.open;           new(:grouping, :open);                end
    def self.close;          new(:grouping, :close);               end
    def self.comma;          new(:grouping, :comma);               end
    def self.logical;        new(:logical);                        end
    def self.combinator;     new(:combinator);                     end
    def self.if;             new(:function, :if);                  end
    def self.round;          new(:function, :round);               end
    def self.roundup;        new(:function, :roundup);             end
    def self.rounddown;      new(:function, :rounddown);           end
    def self.not;            new(:function, :not);                 end
    def self.non_close_plus; new(:grouping, :close).invert.plus;   end
    def self.non_group;      new(:grouping).invert;                end
    def self.non_group_star; new(:grouping).invert.star;           end


    def self.method_missing(name, *args, &block)
      new(:function, name)
    end

    def self.respond_to_missing?(name, include_priv)
      true
    end

  end
end