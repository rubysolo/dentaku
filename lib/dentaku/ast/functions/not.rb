require_relative '../function'

Dentaku::AST::Function.register(:not, :logical, ->(logical) {
  ! logical
})
