require_relative '../function'
require_relative '../../exceptions'

Dentaku::AST::Function.register(:or, :logical, lambda { |*args|
  if args.empty?
    raise Dentaku::ArgumentError.new(
      :too_few_arguments,
      function_name: 'OR()', at_least: 1, given: 0
    ), 'OR() requires at least one argument'
  end

  args.any? do |arg|
    case arg
    when TrueClass, nil
      true
    when FalseClass
      false
    else
      raise Dentaku::ArgumentError.new(
        :incompatible_type,
        function_name: 'AND()', expect: :logical, actual: arg.class
      ), 'AND() requires arguments to be logical expressions'
    end
  end
})
