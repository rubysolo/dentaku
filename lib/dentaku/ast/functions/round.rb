require_relative '../function'

Dentaku::AST::Function.register(:round, :numeric, lambda { |numeric, places = 0|
  Dentaku::AST::Function.numeric(numeric).round(Dentaku::AST::Function.numeric(places || 0).to_i)
})
