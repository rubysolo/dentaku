require 'dentaku/token_matchers'

module Dentaku
  module Math
    def self.exported_methods
      ::Math.methods(false)
    end

    def self.rules
      Math.exported_methods.map do |method|
        [pattern(method), :delegate_to_math]
      end
    end

    def self.patterns
      @patterns ||= Hash[Math.exported_methods.map { |method|
        [method, TokenMatchers.function_token_matchers(method, :arguments)]
      }]
    end

    def self.pattern(name)
      patterns[name]
    end

    def delegate_to_math(func_token, *args)
      function = func_token.value
      _, *tokens, _ = *args
      values = tokens.reject(&:grouping?).map(&:value)

      arity = ::Math.method(function).arity
      unless values.length == arity || arity == -1
        raise "Wrong number of arguments (#{ values.length } for #{ arity })"
      end

      Token.new(:numeric, ::Math.send(function, *values))
    end

    extend self
  end
end
