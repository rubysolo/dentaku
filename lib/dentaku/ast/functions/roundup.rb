require_relative '../function'

Dentaku::AST::Function.register(:roundup, :numeric, ->(numeric, precision=0) {
  if precision == 0 # Ensure int is returned
    numeric.ceil
  else
    tens = 10.0**precision
    (numeric * tens).ceil / tens
  end
})
