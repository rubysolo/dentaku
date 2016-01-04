require_relative '../function'

Dentaku::AST::Function.register(:rounddown, :numeric, ->(numeric, precision=0) {
  tens = 10.0**precision
  result = (numeric * tens).floor / tens
  precision <= 0 ? result.to_i : result
})
