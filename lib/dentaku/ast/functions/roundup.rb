require_relative '../function'

Dentaku::AST::Function.register(:roundup, :numeric, lambda { |numeric, precision = 0|
  precision = Dentaku::NumericParser.ensure_numeric!(precision || 0).to_i
  numeric = Dentaku::NumericParser.ensure_numeric!(numeric)
  # Float#ceil(digits) works on the binary value, so 0.07.ceil(2) is 0.08;
  # going through the shortest decimal form rounds the number as written
  result = if numeric.is_a?(Float)
    BigDecimal(numeric.to_s).ceil(precision).to_f
  else
    numeric.ceil(precision)
  end
  precision <= 0 ? result.to_i : result
})
