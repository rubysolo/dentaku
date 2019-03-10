require 'pry'
require 'simplecov'
require 'codecov'

SimpleCov.formatters = SimpleCov::Formatter::MultiFormatter.new([
  SimpleCov::Formatter::HTMLFormatter,
  SimpleCov::Formatter::Codecov,
])

SimpleCov.minimum_coverage 90
SimpleCov.minimum_coverage_by_file 80

SimpleCov.start do
  add_filter "spec/"
end

RSpec.configure do |c|
  c.before(:all) {
    if Dentaku.respond_to?(:aliases=)
      # add example for alias because we can set aliases just once
      # before `calculator` method called
      Dentaku.aliases = { roundup: ['roundupup'] }
    end
  }
end

# automatically create a token stream from bare values
def token_stream(*args)
  args.map do |value|
    type = type_for(value)
    Dentaku::Token.new(type, value)
  end
end

# make a (hopefully intelligent) guess about type
def type_for(value)
  case value
  when Numeric
    :numeric
  when String
    :string
  when true, false
    :logical
  when :add, :subtract, :multiply, :divide, :mod, :pow
    :operator
  when :open, :close, :comma
    :grouping
  when :lbracket, :rbracket
    :access
  when :le, :ge, :ne, :lt, :gt, :eq
    :comparator
  when :and, :or
    :combinator
  when :if, :round, :roundup, :rounddown, :not
    :function
  else
    :identifier
  end
end

def identifier(name)
  Dentaku::AST::Identifier.new(token(name))
end

def literal(value)
  Dentaku::AST::Literal.new(token(value))
end

def token(value)
  Dentaku::Token.new(type_for(value), value)
end
