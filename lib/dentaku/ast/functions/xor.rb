require_relative '../function'
require_relative '../../exceptions'

Dentaku::AST::Function.register(:xor, :logical, lambda { |*args|
  if args.empty?
    raise Dentaku::ArgumentError.for(
      :too_few_arguments,
      function_name: 'XOR()', at_least: 1, given: 0
    ), 'XOR() requires at least one argument'
  end

  args.count do |arg|
    case arg
    when TrueClass
      true
    when FalseClass, nil
      false
    else
      raise Dentaku::ArgumentError.for(
        :incompatible_type,
        function_name: 'XOR()', expect: :logical, actual: arg.class
      ), 'XOR() requires arguments to be logical expressions'
    end
  end.odd?
})
