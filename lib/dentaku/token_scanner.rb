require 'dentaku/token'

module Dentaku
  class TokenScanner
    def initialize(category, regexp, converter=nil)
      @category  = category
      @regexp    = %r{\A(#{ regexp })}i
      @converter = converter
    end

    def scan(string)
      if m = @regexp.match(string)
        value = raw = m.to_s
        value = @converter.call(raw) if @converter

        return Token.new(@category, value, raw)
      end

      false
    end

    class << self
      def scanners
        @scanners ||= [
          whitespace,
          numeric,
          double_quoted_string,
          single_quoted_string,
          operator,
          grouping,
          comparator,
          combinator,
          function,
          identifier
        ]
      end

      def whitespace
        new(:whitespace, '\s+')
      end

      def numeric
        new(:numeric, '(\d+(\.\d+)?|\.\d+)\b', lambda { |raw| raw =~ /\./ ? BigDecimal.new(raw) : raw.to_i })
      end

      def double_quoted_string
        new(:string, '"[^"]*"', lambda { |raw| raw.gsub(/^"|"$/, '') })
      end

      def single_quoted_string
        new(:string, "'[^']*'", lambda { |raw| raw.gsub(/^'|'$/, '') })
      end

      def operator
        names = { pow: '^', add: '+', subtract: '-', multiply: '*', divide: '/', mod: '%' }.invert
        new(:operator, '\^|\+|-|\*|\/|%', lambda { |raw| names[raw] })
      end

      def grouping
        names = { open: '(', close: ')', comma: ',' }.invert
        new(:grouping, '\(|\)|,', lambda { |raw| names[raw] })
      end

      def comparator
        names = { le: '<=', ge: '>=', ne: '!=', lt: '<', gt: '>', eq: '=' }.invert
        alternate = { ne: '<>', eq: '==' }.invert
        new(:comparator, '<=|>=|!=|<>|<|>|==|=', lambda { |raw| names[raw] || alternate[raw] })
      end

      def combinator
        new(:combinator, '(and|or)\b', lambda {|raw| raw.strip.downcase.to_sym })
      end

      def function
        new(:function, '(\w+\s*(?=\())', lambda {|raw| raw.strip.downcase.to_sym })
      end

      def identifier
        new(:identifier, '\w+\b', lambda {|raw| raw.strip.downcase.to_sym })
      end
    end
  end
end
