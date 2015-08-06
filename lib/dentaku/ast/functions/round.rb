require_relative '../function'

Dentaku::AST::Function.register(:round, ->(numeric, places=nil) {
  numeric.round(places || 0)
})
