require_relative '../function'

Dentaku::AST::Function.register(:avg, :numeric, ->(*args) {
  flatten_args = args.flatten
  if flatten_args.empty?
    raise Dentaku::ArgumentError.for(
        :too_few_arguments,
        function_name: 'AVG()', at_least: 1, given: 0
    ), 'AVG() requires at least one argument'
  end

  flatten_args.map { |arg| Dentaku::AST::Function.numeric(arg) }.reduce(0, :+) / flatten_args.length
})
