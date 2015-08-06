require_relative '../function'

Dentaku::AST::Function.register(:min, :numeric, [:arguments], ->(*args) {
  args.min
})
