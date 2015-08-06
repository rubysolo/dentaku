# import all functions from Ruby's Math module
require_relative "../function"

Math.methods(false).each do |method|
  Dentaku::AST::Function.register(method, :numeric, [:arguments], ->(*args) {
    Math.send(method, *args)
  })
end
