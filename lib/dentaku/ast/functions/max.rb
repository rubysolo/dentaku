require_relative '../function'

Dentaku::AST::Function.register(:max, :numeric, [:arguments], ->(*args) {
  args.max
})
