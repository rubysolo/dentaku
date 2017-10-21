require_relative '../function'

Dentaku::AST::Function.register(:max, :numeric, ->(*args) {
  args.flatten.map { |arg| Dentaku::AST::Function.numeric(arg) }.max
})
