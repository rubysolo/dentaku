require_relative '../function'

Dentaku::AST::Function.register(:or, :logical, lambda { |*args|
  raise ArgumentError, 'OR() requires at least one argument' if args.empty?

  args.any? do |arg|
    case arg
    when TrueClass, nil
      true
    when FalseClass
      false
    else
      raise ArgumentError, 'OR() requires arguments to be logical expressions'
    end
  end
})
