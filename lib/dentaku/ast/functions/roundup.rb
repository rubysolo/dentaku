require_relative '../function'

Dentaku::AST::Function.register(:roundup, ->(numeric) {
  numeric.ceil
})
