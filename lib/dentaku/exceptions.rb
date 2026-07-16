module Dentaku
  class Error < StandardError
    attr_accessor :recipient_variable
  end

  class UnboundVariableError < Error
    attr_reader :unbound_variables

    def initialize(unbound_variables)
      @unbound_variables = unbound_variables
    end
  end

  class MathDomainError < Error
    attr_reader :function_name, :args

    def initialize(function_name, args)
      @function_name = function_name
      @args = args
    end
  end

  class NodeError < Error
    attr_reader :child, :expect, :actual

    def initialize(expect, actual, child)
      @expect = Array(expect)
      @actual = actual
      @child = child
    end
  end

  class ParseError < Error
    attr_reader :reason, :meta

    def initialize(reason, message = nil, **meta)
      super(message || self.class.default_message(reason, meta))
      @reason = reason
      @meta = meta
    end

    private_class_method :new

    VALID_REASONS = %i[
      node_invalid too_few_operands too_many_operands undefined_function
      unprocessed_token unknown_case_token unbalanced_bracket
      unbalanced_parenthesis unknown_grouping_token not_implemented_token_category
      invalid_statement
    ].freeze

    def self.for(reason, message = nil, **meta)
      unless VALID_REASONS.include?(reason)
        raise ::ArgumentError, "Unhandled #{reason}"
      end

      new(reason, message, **meta)
    end

    def self.default_message(reason, meta)
      case reason
      when :node_invalid
        if meta.key?(:operator) && meta.key?(:expect) && meta.key?(:actual)
          "#{meta.fetch(:operator)} requires #{expected_operand_description(meta.fetch(:expect))}, not #{formatted_actual(meta.fetch(:actual))}"
        else
          'Invalid node'
        end
      when :too_few_operands
        "#{meta.fetch(:operator)} has too few operands (given #{meta.fetch(:actual)}, expected #{meta.fetch(:expect)})"
      when :too_many_operands
        "#{meta.fetch(:operator)} has too many operands (given #{meta.fetch(:actual)}, expected #{meta.fetch(:expect)})"
      when :undefined_function
        "Undefined function #{meta.fetch(:function_name)}"
      when :unprocessed_token
        "Unprocessed token #{meta.fetch(:token_name)}"
      when :unknown_case_token
        "Unknown case token #{meta.fetch(:token_name)}"
      when :unbalanced_bracket
        'Unbalanced bracket'
      when :unbalanced_parenthesis
        'Unbalanced parenthesis'
      when :unknown_grouping_token
        "Unknown grouping token #{meta.fetch(:token_name)}"
      when :not_implemented_token_category
        "Not implemented for tokens of category #{meta.fetch(:token_category)}"
      when :invalid_statement
        'Invalid statement'
      else
        raise ::ArgumentError, "Unhandled #{reason}"
      end
    end

    def self.expected_operand_description(expectation)
      expected = Array(expectation)
      if expected.include?(:incompatible)
        'operands that are numeric or compatible types'
      elsif expected == [:numeric]
        'numeric operands'
      elsif expected == [:logical]
        'logical operands'
      else
        "#{expected.join(', ')} operands"
      end
    end

    def self.formatted_actual(actual)
      actual.respond_to?(:to_sym) ? actual.to_sym : actual
    end
  end

  class TokenizerError < Error
    attr_reader :reason, :meta

    def initialize(reason, **meta)
      @reason = reason
      @meta = meta
    end

    private_class_method :new

    VALID_REASONS = %i[
      parse_error
      too_many_closing_parentheses
      too_many_opening_parentheses
      unexpected_zero_width_match
    ].freeze

    def self.for(reason, **meta)
      unless VALID_REASONS.include?(reason)
        raise ::ArgumentError, "Unhandled #{reason}"
      end

      new(reason, **meta)
    end
  end

  class ArgumentError < ::ArgumentError
    attr_reader :reason, :meta
    attr_accessor :recipient_variable

    def initialize(reason, **meta)
      @reason = reason
      @meta = meta
    end

    private_class_method :new

    VALID_REASONS = %i[
      incompatible_type
      invalid_operator
      invalid_value
      too_few_arguments
      wrong_number_of_arguments
    ].freeze

    def self.for(reason, **meta)
      unless VALID_REASONS.include?(reason)
        raise ::ArgumentError, "Unhandled #{reason}"
      end

      new(reason, **meta)
    end
  end

  class ZeroDivisionError < ::ZeroDivisionError
    attr_accessor :recipient_variable
  end
end
