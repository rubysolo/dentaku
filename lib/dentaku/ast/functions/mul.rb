require_relative '../function'

Dentaku::AST::Function.register(:mul, :numeric, ->(*args) {
  flatten_args = args.flatten
  if flatten_args.empty?
    raise Dentaku::ArgumentError.for(
        :too_few_arguments,
        function_name: 'MUL()', at_least: 1, given: 0
    ), 'MUL() requires at least one argument'
  end

  flatten_args.map { |arg| Dentaku::AST::Function.numeric(arg) }.reduce(1, :*)
})
