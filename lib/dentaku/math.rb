require 'dentaku/token_matchers'

module Dentaku
  module Math
    def self.exported_methods
      ::Math.methods(false)
    end

    def self.rules
      Math.exported_methods.map do |method|
        [pattern(method), method]
      end
    end

    def self.patterns
      @patterns ||= Hash[Math.exported_methods.map { |method|
        [method, TokenMatchers.function_token_matchers(method, :arguments)]
      }]
    end

    def self.pattern(name)
      Math.patterns[name]
    end

    def delegate_to_math(method, args)
      ::Math.send(method, *args)
    end

    Math.exported_methods.each do |method|
      define_method method do |*args|
        function, _, *tokens, _ = *args
        values = tokens.map(&:value).select { |value| value.is_a?(Numeric) }
        result = delegate_to_math method, values
        Token.new(:numeric, result)
      end
    end

    extend self
  end
end
