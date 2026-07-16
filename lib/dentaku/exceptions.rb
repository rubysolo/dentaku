module Dentaku
  # Shared by all Dentaku exceptions so that `rescue Dentaku::Error` catches
  # everything the gem raises, including exceptions that subclass Ruby
  # built-ins (Dentaku::ArgumentError, Dentaku::ZeroDivisionError).
  module Error
    attr_accessor :recipient_variable
  end

  class BaseError < StandardError
    include Error
  end

  class UnboundVariableError < BaseError
    attr_reader :unbound_variables

    def initialize(unbound_variables)
      @unbound_variables = unbound_variables
    end
  end

  class MathDomainError < BaseError
    attr_reader :function_name, :args

    def initialize(function_name, args)
      @function_name = function_name
      @args = args
    end
  end

  class NodeError < BaseError
    attr_reader :child, :expect, :actual

    def initialize(expect, actual, child)
      @expect = Array(expect)
      @actual = actual
      @child = child
    end
  end

  class ParseError < BaseError
    attr_reader :reason, :meta

    def initialize(reason, **meta)
      @reason = reason
      @meta = meta
      super(default_message)
    end

    private_class_method :new

    VALID_REASONS = %i[
      node_invalid too_few_operands too_many_operands undefined_function
      unprocessed_token unknown_case_token unbalanced_bracket
      unbalanced_parenthesis unknown_grouping_token not_implemented_token_category
      invalid_statement
    ].freeze

    def self.for(reason, **meta)
      unless VALID_REASONS.include?(reason)
        raise ::ArgumentError, "Unhandled #{reason}"
      end

      new(reason, **meta)
    end

    private

    def default_message
      case reason
      when :node_invalid
        if meta.key?(:operator)
          expected = Array(meta[:expect]).map { |e| e == :incompatible ? :compatible : e }
          "#{meta[:operator]} requires #{expected.join(', ')} operands, but got #{meta[:actual]}"
        else
          "Node is invalid"
        end
      when :too_few_operands
        "#{meta[:operator]} has too few operands (given #{meta[:actual]}, expected #{meta[:expect]})"
      when :too_many_operands
        "#{meta[:operator]} has too many operands (given #{meta[:actual]}, expected #{meta[:expect]})"
      when :undefined_function
        "Undefined function #{meta[:function_name]}"
      when :unprocessed_token
        "Unprocessed token #{meta[:token_name]}"
      when :unknown_case_token
        "Unknown case token #{meta[:token_name]}"
      when :unbalanced_bracket
        "Unbalanced bracket"
      when :unbalanced_parenthesis
        "Unbalanced parenthesis"
      when :unknown_grouping_token
        "Unknown grouping token #{meta[:token_name]}"
      when :not_implemented_token_category
        "Not implemented for tokens of category #{meta[:token_category]}"
      when :invalid_statement
        "Invalid statement"
      end
    end
  end

  class TokenizerError < BaseError
    attr_reader :reason, :meta

    def initialize(reason, **meta)
      @reason = reason
      @meta = meta
      super(default_message)
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

    private

    def default_message
      case reason
      when :parse_error
        "parse error at: '#{meta[:at]}'"
      when :too_many_opening_parentheses
        "too many opening parentheses"
      when :too_many_closing_parentheses
        "too many closing parentheses"
      when :unexpected_zero_width_match
        "unexpected zero-width match (:#{meta[:token_category]}) at '#{meta[:at]}'"
      end
    end
  end

  class ArgumentError < ::ArgumentError
    include Error

    attr_reader :reason, :meta

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
    include Error
  end
end
