require_relative '../function'

Dentaku::AST::Function.register(:and, :logical, lambda { |*args|
  raise ArgumentError, 'AND() requires at least one argument' if args.empty?

  args.all? do |arg|
    case arg
    when TrueClass, nil
      true
    when FalseClass
      false
    else
      raise ArgumentError, 'AND() requires arguments to be logical expressions'
    end
  end
})
