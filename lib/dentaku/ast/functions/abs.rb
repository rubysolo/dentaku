require_relative '../function'

Dentaku::AST::Function.register(:abs, :numeric, lambda { |numeric|
  Dentaku::AST::Function.numeric(numeric).abs
})
