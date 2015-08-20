require 'bigdecimal'
require 'dentaku/token'

module Dentaku
  class TokenScanner
    def initialize(category, regexp, converter=nil, condition=nil)
      @category  = category
      @regexp    = %r{\A(#{ regexp })}i
      @converter = converter
      @condition = condition || ->(*) { true }
    end

    def scan(string, last_token=nil)
      if (m = @regexp.match(string)) && @condition.call(last_token)
        value = raw = m.to_s
        value = @converter.call(raw) if @converter

        return Array(value).map do |v|
          Token === v ? v : Token.new(@category, v, raw)
        end
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
          negate,
          operator,
          grouping,
          comparator,
          combinator,
          boolean,
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

      def negate
        new(:operator, '-', lambda { |raw| :negate }, lambda { |last_token|
          last_token.nil?             ||
          last_token.is?(:operator)   ||
          last_token.is?(:comparator) ||
          last_token.is?(:combinator) ||
          last_token.value == :open   ||
          last_token.value == :comma
        })
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
        new(:combinator, '(and|or)\b', lambda { |raw| raw.strip.downcase.to_sym })
      end

      def boolean
        new(:logical, '(true|false)\b', lambda { |raw| raw.strip.downcase == 'true' })
      end

      def function
        new(:function, '\w+\s*\(', lambda do |raw|
          function_name = raw.gsub('(', '')
          [Token.new(:function, function_name.strip.downcase.to_sym, function_name), Token.new(:grouping, :open, '(')]
        end)
      end

      def identifier
        new(:identifier, '\w+\b', lambda { |raw| raw.strip.downcase.to_s })
      end
    end
  end
end
