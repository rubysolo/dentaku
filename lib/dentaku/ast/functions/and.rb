require_relative '../function'
require_relative '../../exceptions'

Dentaku::AST::Function.register(:and, :logical, lambda { |*args|
  if args.empty?
    raise Dentaku::ArgumentError.for(
      :too_few_arguments,
      function_name: 'AND()', at_least: 1, given: 0
    ), 'AND() requires at least one argument'
  end

  args.all? do |arg|
    case arg
    when TrueClass
      true
    when FalseClass, nil
      false
    else
      raise Dentaku::ArgumentError.for(
        :incompatible_type,
        function_name: 'AND()', expect: :logical, actual: arg.class
      ), 'AND() requires arguments to be logical expressions'
    end
  end
})
