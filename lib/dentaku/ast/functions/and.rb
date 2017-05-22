require_relative '../function'
require_relative '../../exceptions'

Dentaku::AST::Function.register(:and, :logical, lambda { |*args|
  fail Dentaku::ArgumentError, 'AND() requires at least one argument' if args.empty?

  args.all? do |arg|
    case arg
    when TrueClass, nil
      true
    when FalseClass
      false
    else
      fail Dentaku::ArgumentError, 'AND() requires arguments to be logical expressions'
    end
  end
})
