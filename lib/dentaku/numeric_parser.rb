module Dentaku
  module NumericParser
    NUMERIC_PATTERN = '((?:\d+(\.\d+)?|\.\d+)(?:(e|E)(\+|-)?\d+)?)\b'.freeze
    # e.g:  [2, 1.2, .5, 1e10, 1.5E-10]
    HEXADECIMAL_PATTERN = '(0x[0-9a-f]+)\b'.freeze
    # e.g:  [0x1A3F]

    class << self
      def match(string)
        regex = %r{\A(-?(#{ NUMERIC_PATTERN }|#{ HEXADECIMAL_PATTERN }))\z}i
        string.match(regex)
      end

      def match_numeric(string)
        regex = %r{\A(#{ NUMERIC_PATTERN })\z}i
        string.match(regex)
      end

      def match_hexadecimal(string)
        regex = %r{\A(#{ HEXADECIMAL_PATTERN })\z}i
        string.match(regex)
      end

      def parse_numeric_string(raw)
        raw =~ /(\.|e|E)/ ? BigDecimal(raw, Float::DIG + 1) : raw.to_i
      end

      def parse_hexadecimal_string(raw)
        raw[2..-1].to_i(16)
      end

      def parse_string(raw)
        return nil unless !!match(raw)

        is_negative = raw.start_with?('-')
        number_part = is_negative ? raw[1..-1] : raw

        value = if number_part =~ /\A0x/i
          parse_hexadecimal_string(number_part)
        else
          parse_numeric_string(number_part)
        end

        is_negative ? -value : value
      end

      # @return [Numeric] where possible it returns an Integer otherwise a BigDecimal.
      # An Exception will be raised if a value is passed that cannot be cast to a Number.
      def ensure_numeric!(value)
        return value if value.is_a?(::Numeric)

        if value.is_a?(::String)
          number = parse_string(value)
          return number if number
        end

        raise Dentaku::ArgumentError.for(:incompatible_type, value: value, for: Numeric),
          "'#{value || value.class}' is not coercible to numeric"
      end

      def ensure_numeric(value)
        ensure_numeric!(value)
      rescue Dentaku::ArgumentError
        nil
      end
    end
  end
end
