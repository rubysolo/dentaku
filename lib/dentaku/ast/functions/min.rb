require_relative '../function'

Dentaku::AST::Function.register(:min, :numeric, ->(*args) {
  args.flatten.map { |arg| Dentaku::AST::Function.numeric(arg) }.min
})
