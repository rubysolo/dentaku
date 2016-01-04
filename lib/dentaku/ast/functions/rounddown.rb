require_relative '../function'

Dentaku::AST::Function.register(:rounddown, :numeric, ->(numeric, precision=0) {
  if precision == 0 # Ensure int is returned
    numeric.floor
  else
    tens = 10.0**precision
    (numeric * tens).floor / tens
  end
})
