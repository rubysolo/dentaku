# import all functions from Ruby's Math module
require_relative "../function"

Math.methods(false).each do |method|
  next if method.to_s.include?("!")
  Dentaku::AST::Function.register(method, :numeric, ->(*args) {
    Math.send(method, *args)
  })
end
