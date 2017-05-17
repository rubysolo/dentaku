require_relative '../function'

Dentaku::AST::Function.register(:switch, :logical, lambda { |*args|
  value = args.shift
  default = args.pop if args.size.odd?
  match = args.find_index.each_with_index { |arg, index| index.even? && arg == value }
  match ? args[match + 1] : default
})
