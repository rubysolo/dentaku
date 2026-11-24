require_relative '../function'
require_relative './directed_rounding'

Dentaku::AST::Function.register(:rounddown, :numeric, lambda { |numeric, precision = 0|
  Dentaku::DirectedRounding.call('ROUNDDOWN', numeric, precision, :floor)
})
