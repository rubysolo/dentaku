require_relative '../function'

Dentaku::AST::Function.register(:intercept, :list, ->(*args) {
  flatten_args = args.flatten
  if flatten_args.length != 2 || !flatten_args.all? { |arg| arg.is_a?(Array) } || flatten_args.any? { |arg| arg.empty? }
    raise Dentaku::ArgumentError.for(
        :wrong_number_of_arguments,
        function_name: 'INTERCEPT()', exact: 2, given: flatten_args.length
    ), 'INTERCEPT() requires exactly two arrays of numbers'
  end

  x_values, y_values = flatten_args
  if x_values.length != y_values.length
    raise Dentaku::ArgumentError.for(
        :unequal_array_lengths,
        function_name: 'INTERCEPT()'
    ), 'INTERCEPT() requires arrays of equal length'
  end

  x_values = x_values.map { |arg| Dentaku::AST::Function.numeric(arg) }
  y_values = y_values.map { |arg| Dentaku::AST::Function.numeric(arg) }

  x_sum = x_values.reduce(0, :+)
  y_sum = y_values.reduce(0, :+)
  xy_sum = x_values.zip(y_values).map { |x, y| x * y }.reduce(0, :+)
  x_square_sum = x_values.map { |x| x**2 }.reduce(0, :+)

  n = x_values.length

  slope = (n * xy_sum - x_sum * y_sum) / (n * x_square_sum - x_sum**2)
  intercept = y_values.reduce(:+) / n - slope * x_values.reduce(:+) / n

  BigDecimal(intercept)
})

