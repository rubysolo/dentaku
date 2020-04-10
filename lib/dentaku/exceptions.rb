module Dentaku
  class Error < StandardError
  end

  class UnboundVariableError < Error
    attr_accessor :recipient_variable

    attr_reader :unbound_variables

    def initialize(unbound_variables)
      @unbound_variables = unbound_variables
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

  class TokenizerError < Error
    attr_reader :reason, :meta

    def initialize(reason, **meta)
      @reason = reason
      @meta = meta
    end

    private_class_method :new

    VALID_REASONS = %i[
      parse_error too_many_opening_parentheses too_many_closing_parentheses
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

    def initialize(reason, **meta)
      @reason = reason
      @meta = meta
    end

    private_class_method :new

    VALID_REASONS = %i[
      invalid_operator invalid_value too_few_arguments
      too_much_arguments incompatible_type
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
