require_relative '../function'

Dentaku::AST::Function.register(:max, ->(*args) {
  args.max
})
