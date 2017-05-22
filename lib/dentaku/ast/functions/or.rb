require_relative '../function'
require_relative '../../exceptions'

Dentaku::AST::Function.register(:or, :logical, lambda { |*args|
  fail Dentaku::ArgumentError, 'OR() requires at least one argument' if args.empty?

  args.any? do |arg|
    case arg
    when TrueClass, nil
      true
    when FalseClass
      false
    else
      fail Dentaku::ArgumentError, 'OR() requires arguments to be logical expressions'
    end
  end
})
