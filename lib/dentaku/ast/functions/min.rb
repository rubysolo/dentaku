require_relative '../function'

Dentaku::AST::Function.register(:min, :numeric, ->(*args) {
  args.sort_by(&:to_d).first
})
