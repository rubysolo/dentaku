require 'bigdecimal'
require_relative '../../numeric_limits'
require_relative '../../numeric_parser'

module Dentaku
  # Shared by ROUNDUP (:ceil) and ROUNDDOWN (:floor).
  module DirectedRounding
    def self.call(numeric, precision, direction)
      precision = NumericParser.ensure_numeric!(precision || 0).to_i
      numeric = NumericParser.ensure_numeric!(numeric)
      # Float#ceil(digits) works on the binary value, so 0.07.ceil(2) is 0.08;
      # going through the shortest decimal form rounds the number as written
      decimal = numeric.is_a?(Float) ? BigDecimal(numeric.to_s) : numeric

      # Integer#ceil(-n) builds 10**n in one uninterruptible C call, even when
      # the answer is 0, so a precision past the number's digits is answered here
      if precision < 0 && -precision > BigDecimal(decimal).exponent
        return beyond_digits(numeric, precision, direction)
      end

      result = decimal.public_send(direction, precision)
      result = result.to_f if numeric.is_a?(Float)
      precision <= 0 ? result.to_i : result
    end

    # |numeric| < 10**-precision, so the result is 0 or ±10**-precision
    def self.beyond_digits(numeric, precision, direction)
      away_from_zero = direction == :ceil ? numeric.positive? : numeric.negative?
      return 0 unless away_from_zero

      # 10**n has n + 1 digits
      NumericLimits.check_digits!(1 - precision)
      (numeric.positive? ? 1 : -1) * 10**-precision
    end
    private_class_method :beyond_digits
  end
end
