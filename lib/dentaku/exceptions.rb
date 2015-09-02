module Dentaku
  class UnboundVariableError < StandardError
    attr_reader :unbound_variables

    def initialize(unbound_variables)
      @unbound_variables = unbound_variables
      super("no value provided for variables: #{ unbound_variables.join(', ') }")
    end
  end
end
