module Dentaku
  class UnboundVariableError < StandardError
    attr_accessor :recipient_variable

    attr_reader :unbound_variables

    def initialize(unbound_variables)
      @unbound_variables = unbound_variables
      super("no value provided for variables: #{ unbound_variables.join(', ') }")
    end
  end

  class ParseError < StandardError
  end

  class ArgumentError < ::ArgumentError
  end

  class ZeroDivisionError < ::ZeroDivisionError
    attr_accessor :recipient_variable
  end
end
