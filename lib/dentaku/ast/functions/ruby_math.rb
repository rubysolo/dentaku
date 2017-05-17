# import all functions from Ruby's Math module
require_relative '../function'

Math.methods(false).each do |method|
  Dentaku::AST::Function.register(method, :numeric, lambda { |*args|
    Math.send(method, *args.map { |arg| Dentaku::AST::Function.numeric(arg) })
  })
end
