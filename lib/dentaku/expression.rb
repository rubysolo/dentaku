require 'dentaku/tokenizer'

module Dentaku
  class Expression
    attr_reader :tokens, :variables

    def initialize(expr, variables={})
      @tokens    = Tokenizer.new.tokenize(expr)
      @variables = string_keys(variables)
      bind!
    end

    def identifiers
      @tokens.select { |t| t.is? :identifier }.map(&:value)
    end

    def unbound?
      identifiers.any?
    end

    def bind(vars={})
      self.class.allocate.tap do |bound|
        bound.instance_variable_set :@tokens, tokens.dup
        bound.instance_variable_set :@variables, variables.merge(string_keys(vars))
        bound.bind!
      end
    end

    def bind!
      @tokens.map! do |token|
        if token.is?(:identifier)
          replace_identifier_with_value(token)
        else
          token
        end
      end
    end

    private

    def string_keys(hash)
      Hash[hash.map { |k,v| [k.to_s, v] }]
    end


    def replace_identifier_with_value(token)
      key = token.value.to_s

      if variables.key? key
        value = variables[key]
        type  = type_for_value(value)

        Token.new(type, value)
      else
        token
      end
    end

    def type_for_value(value)
      case value
      when String then :string
      when TrueClass, FalseClass then :logical
      else :numeric
      end
    end
  end
end
