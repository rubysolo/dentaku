require_relative '../function'

Dentaku::AST::Function.register(:min, :numeric, ->(*args) {
  args.min
})
