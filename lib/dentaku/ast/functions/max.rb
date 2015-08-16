require_relative '../function'

Dentaku::AST::Function.register(:max, :numeric, ->(*args) {
  args.max
})
