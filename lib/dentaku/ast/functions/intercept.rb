require_relative '../function'

Dentaku::AST::Function.register(:intercept, :list, ->(*args) {
  if args.length != 2
    raise Dentaku::ArgumentError.for(
        :wrong_number_of_arguments,
        function_name: 'INTERCEPT()', exact: 2, given: args.length
    ), 'INTERCEPT() requires exactly two arrays of numbers'
  end

  x_values, y_values = args
  if !x_values.is_a?(Array) || !y_values.is_a?(Array) || x_values.length != y_values.length
    raise Dentaku::ArgumentError.for(
        :invalid_value,
        function_name: 'INTERCEPT()'
    ), 'INTERCEPT() requires arrays of equal length'
  end

  n = x_values.length.to_f
  x_values = x_values.map { |arg| Dentaku::AST::Function.numeric(arg) }
  y_values = y_values.map { |arg| Dentaku::AST::Function.numeric(arg) }

  x_avg = x_values.sum / n
  y_avg = y_values.sum / n

  xy_sum = x_values.zip(y_values).map { |x, y| (x_avg - x) * (y_avg - y) }.sum
  x_square_sum = x_values.map { |x| (x_avg - x)**2 }.sum

  slope = xy_sum / x_square_sum
  intercept = x_values.zip(y_values).map { |x, y| y - slope * x }.sum / n

  BigDecimal(intercept, Float::DIG + 1)
})
