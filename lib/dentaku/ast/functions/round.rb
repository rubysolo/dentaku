require_relative '../function'

Dentaku::AST::Function.register(:round, :numeric, ->(numeric, places=nil) {
  numeric.round(places || 0)
})
