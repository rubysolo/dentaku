require 'bigdecimal'
require 'time'
require 'dentaku/string_casing'
require 'dentaku/token'

module Dentaku
  class TokenScanner
    extend StringCasing

    def initialize(category, regexp, converter = nil, condition = nil)
      @category  = category
      @regexp    = %r{\A(#{ regexp })}i
      @converter = converter
      @condition = condition || ->(*) { true }
    end

    def scan(string, last_token = nil)
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
      attr_reader :case_sensitive

      def available_scanners
        [
          :null,
          :whitespace,
          :datetime, # before numeric so it can pick up timestamps
          :numeric,
          :hexadecimal,
          :double_quoted_string,
          :single_quoted_string,
          :negate,
          :combinator,
          :operator,
          :grouping,
          :array,
          :access,
          :case_statement,
          :comparator,
          :boolean,
          :function,
          :identifier
        ]
      end

      def register_default_scanners
        register_scanners(available_scanners)
      end

      def register_scanners(scanner_ids)
        @scanners = scanner_ids.each_with_object({}) do |id, scanners|
          scanners[id] = self.send(id)
        end
      end

      def register_scanner(id, scanner)
        @scanners[id] = scanner
      end

      def scanners=(scanner_ids)
        @scanners.select! { |k, v| scanner_ids.include?(k) }
      end

      def scanners(options = {})
        @case_sensitive = options.fetch(:case_sensitive, false)
        @scanners.values
      end

      def whitespace
        new(:whitespace, '\s+')
      end

      def null
        new(:null, 'null\b')
      end

      # NOTE: Convert to DateTime as Array(Time) returns the parts of the time for some reason
      def datetime
        new(:datetime, /\d{2}\d{2}?-\d{1,2}-\d{1,2}( \d{1,2}:\d{1,2}:\d{1,2})? ?(Z|((\+|\-)\d{2}\:?\d{2}))?/, lambda { |raw| Time.parse(raw).to_datetime })
      end

      def numeric
        new(:numeric, '((?:\d+(\.\d+)?|\.\d+)(?:(e|E)(\+|-)?\d+)?)\b', lambda { |raw|
          raw =~ /\./ ? BigDecimal(raw) : raw.to_i
        })
      end

      def hexadecimal
        new(:numeric, '(0x[0-9a-f]+)\b', lambda { |raw| raw[2..-1].to_i(16) })
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
        names = {
          pow: '^', add: '+', subtract: '-', multiply: '*', divide: '/', mod: '%', bitor: '|', bitand: '&'
        }.invert
        new(:operator, '\^|\+|-|\*|\/|%|\||&', lambda { |raw| names[raw] })
      end

      def grouping
        names = { open: '(', close: ')', comma: ',' }.invert
        new(:grouping, '\(|\)|,', lambda { |raw| names[raw] })
      end

      def array
        names = { array_start: '{', array_end: '}', }.invert
        new(:array, '\{|\}|,', lambda { |raw| names[raw] })
      end

      def access
        names = { lbracket: '[', rbracket: ']' }.invert
        new(:access, '\[|\]', lambda { |raw| names[raw] })
      end

      def case_statement
        names = { open: 'case', close: 'end', then: 'then', when: 'when', else: 'else' }.invert
        new(:case, '(case|end|then|when|else)\b', lambda { |raw| names[raw.downcase] })
      end

      def comparator
        names = { le: '<=', ge: '>=', ne: '!=', lt: '<', gt: '>', eq: '=' }.invert
        alternate = { ne: '<>', eq: '==' }.invert
        new(:comparator, '<=|>=|!=|<>|<|>|==|=', lambda { |raw| names[raw] || alternate[raw] })
      end

      def combinator
        names = { and: '&&', or: '||' }.invert
        new(:combinator, '(and|or|&&|\|\|)\s', lambda { |raw|
          norm = raw.strip.downcase
          names.fetch(norm) { norm.to_sym }
        })
      end

      def boolean
        new(:logical, '(true|false)\b', lambda { |raw| raw.strip.downcase == 'true' })
      end

      def function
        new(:function, '\w+!?\s*\(', lambda do |raw|
          function_name = raw.gsub('(', '')
          [
            Token.new(:function, function_name.strip.downcase.to_sym, function_name),
            Token.new(:grouping, :open, '(')
          ]
        end)
      end

      def identifier
        new(:identifier, '[[[:word:]]\.]+\b', lambda { |raw| standardize_case(raw.strip) })
      end
    end

    register_default_scanners
  end
end
