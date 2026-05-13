require_relative '../function'

Dentaku::AST::Function.register(:abs, :numeric, lambda { |numeric|
  Dentaku::NumericParser.ensure_numeric!(numeric).abs
})
