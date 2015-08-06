require_relative '../function'

Dentaku::AST::Function.register(:min, ->(*args) {
  args.min
})
