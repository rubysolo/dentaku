require 'dentaku/tokenizer'

module Dentaku
  class Expression
    attr_reader :tokens

    def initialize(string, variables={})
      @raw = string
      @tokenizer ||= Tokenizer.new
      @tokens = @tokenizer.tokenize(@raw)
      replace_identifiers_with_values(variables)
    end

    def identifiers
      @tokens.select { |t| t.category == :identifier }.map { |t| t.value }
    end

    def unbound?
      identifiers.any?
    end

    private

    def replace_identifiers_with_values(variables)
      @tokens.map! do |token|
        if token.is?(:identifier)
          replace_identifier_with_value(token, variables)
        else
          token
        end
      end
    end

    def replace_identifier_with_value(token, variables)
      key = token.value.to_sym

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
