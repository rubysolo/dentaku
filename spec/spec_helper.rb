# automatically create a token stream from bare values
def token_stream(*args)
  args.map do |value|
    type = type_for(value)
    value = (value == :true) if type == :logical
    Dentaku::Token.new(type, value)
  end
end

# make a (hopefully intelligent) guess about type
def type_for(value)
  case value
  when Numeric
    :numeric
  when :add, :subtract, :multiply, :divide, :mod
    :operator
  when :open, :close, :comma
    :grouping
  when :le, :ge, :ne, :ne, :lt, :gt, :eq
    :comparator
  when :and, :or
    :combinator
  when :true, :false
    :logical
  when :if, :round, :roundup, :rounddown, :not
    :function
  else
    :identifier
  end
end

