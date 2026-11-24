require_relative '../function'
require_relative './directed_rounding'

Dentaku::AST::Function.register(:roundup, :numeric, lambda { |numeric, precision = 0|
  Dentaku::DirectedRounding.call('ROUNDUP', numeric, precision, :ceil)
})
