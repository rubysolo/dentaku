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
  end

  class TokenizerError < BaseError
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
