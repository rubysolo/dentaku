require 'bigdecimal'
require_relative '../../exceptions'
require_relative '../../numeric_parser'

module Dentaku
  # Shared by ROUNDUP (:ceil) and ROUNDDOWN (:floor).
  module DirectedRounding
    # The furthest a precision can reach past a number's own digits while
    # rounding away from zero. It matches the 10.0**precision scaling used
    # before 4.2.0, which failed beyond Float's range.
    MAX_PRECISION_BEYOND_DIGITS = Float::MAX_10_EXP

    def self.call(function_name, numeric, precision, direction)
      precision = NumericParser.ensure_numeric!(precision || 0).to_i
      numeric = NumericParser.ensure_numeric!(numeric)
      # Float#ceil(digits) works on the binary value, so 0.07.ceil(2) is 0.08;
      # going through the shortest decimal form rounds the number as written
      decimal = numeric.is_a?(Float) ? BigDecimal(numeric.to_s) : numeric

      # Integer#ceil(-n) builds 10**n in one uninterruptible C call, even when
      # the answer is 0, so a precision past the number's digits is answered here
      if precision < 0 && -precision > BigDecimal(decimal).exponent
        return beyond_digits(function_name, numeric, precision, direction)
      end

      result = decimal.public_send(direction, precision)
      result = result.to_f if numeric.is_a?(Float)
      precision <= 0 ? result.to_i : result
    end

    # |numeric| < 10**-precision, so the result is 0 or ±10**-precision
    def self.beyond_digits(function_name, numeric, precision, direction)
      away_from_zero = direction == :ceil ? numeric.positive? : numeric.negative?
      return 0 unless away_from_zero

      if -precision > MAX_PRECISION_BEYOND_DIGITS
        raise ArgumentError.for(
          :invalid_value,
          function_name: function_name,
          expected: "precision for #{function_name}()",
          actual: precision
        )
      end

      (numeric.positive? ? 1 : -1) * 10**-precision
    end
    private_class_method :beyond_digits
  end
end
