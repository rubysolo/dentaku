require_relative '../function'

Dentaku::AST::Function.register(:rounddown, :numeric, ->(numeric) {
  numeric.floor
})
