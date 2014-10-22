module Dentaku
  class UnboundVariableError < StandardError
    attr_reader :unbound_variables

    def initialize(unbound_variables)
      @unbound_variables = unbound_variables
    end
  end
end
