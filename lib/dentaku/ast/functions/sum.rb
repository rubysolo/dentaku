require_relative '../function'

Dentaku::AST::Function.register(:sum, :numeric, ->(*args) {
  if args.empty?
    raise Dentaku::ArgumentError.for(
        :too_few_arguments,
        function_name: 'SUM', expected: 1.., actual: 0
    ), 'SUM() requires at least one argument'
  end

  args.flatten.map { |arg| Dentaku::NumericParser.ensure_numeric!(arg) }.reduce(0, :+)
})
