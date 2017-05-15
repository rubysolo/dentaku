require_relative '../function'

Dentaku::AST::Function.register(:max, :numeric, ->(*args) {
  args.sort_by(&:to_d).reverse.first
})
