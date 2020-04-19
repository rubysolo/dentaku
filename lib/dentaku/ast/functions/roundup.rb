require_relative '../function'

Dentaku::AST::Function.register(:roundup, :numeric, lambda { |numeric, precision = 0|
  precision = Dentaku::AST::Function.numeric(precision || 0).to_i
  tens = 10.0**precision
  result = (Dentaku::AST::Function.numeric(numeric) * tens).ceil / tens
  precision <= 0 ? result.to_i : result
})
