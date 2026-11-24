require 'bigdecimal'
require_relative './exceptions'

module Dentaku
  # Ruby does bignum arithmetic in single C calls that Timeout can't
  # interrupt, so a short formula like `7 ^ 100000000` or
  # `ROUND(1e100000000)` could tie up a thread for hours. Numbers are kept
  # to MAX_DIGITS decimal digits: values longer than that are rejected where
  # they're used, and the operators that grow numbers fastest (`^`, `<<`)
  # are checked before they run.
  module NumericLimits
    MAX_DIGITS = 10_000

    LOG10_2 = Math.log10(2)

    class << self
      # Approximate decimal digits needed to hold value exactly. For a
      # BigDecimal that is the larger of its integer digits (what to_i
      # would build) and its significant digits (what arithmetic carries).
      def digits(value)
        case value
        when ::Integer
          (value.bit_length * LOG10_2).ceil
        when ::BigDecimal
          value.finite? ? [value.exponent, value.n_significant_digits].max : 0
        else
          0
        end
      end

      def check!(value)
        check_digits!(digits(value), value.class)
        value
      end

      # For callers that know a result's size before building it
      def check_digits!(count, type = ::Integer)
        raise too_long(type) if count > MAX_DIGITS
      end

      # base ** exponent has about |exponent| times as many digits as base
      def check_power!(base, exponent)
        return unless base.is_a?(::Integer) || base.is_a?(::BigDecimal)
        return unless exponent.is_a?(::Numeric) && exponent.real?
        return if base.zero? || base.abs == 1

        magnitude = base.is_a?(::Integer) ? Math.log10(base.abs) : digits(base)
        check_digits!(magnitude * exponent.abs, base.class)
      end

      def check_shift!(value, bits)
        return unless value.is_a?(::Integer) && bits.is_a?(::Integer)
        return if value.zero? || bits <= 0

        check_digits!((value.bit_length + bits) * LOG10_2)
      end

      private

      # Carries only the class: printing a huge value is itself slow
      def too_long(type)
        Dentaku::ArgumentError.for(:invalid_value, actual: type)
          .exception("Number has more than #{MAX_DIGITS} digits")
      end
    end
  end
end
