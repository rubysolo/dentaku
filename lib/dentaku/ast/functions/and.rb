require_relative '../function'
require_relative '../../exceptions'

Dentaku::AST::Function.register(:and, :logical, lambda { |*args|
  if args.empty?
    raise Dentaku::ArgumentError.for(
      :too_few_arguments,
      function_name: 'AND', expected: 1.., actual: 0
    )
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
        function_name: 'AND', expected: :logical, actual: arg
      )
    end
  end
})
