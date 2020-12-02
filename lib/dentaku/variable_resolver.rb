module Dentaku
  class VariableResolver
    # default variable resolver for dentaku
    attr_reader :calculator

    def initialize(calculator)
      @calculator = calculator
    end

    # default simplistic implementation assumes flattened memory keys
    def unbound_variables(ast_node)
      ast_node.dependencies - calculator.memory.keys
    end

    def fetch(variable_name)
      calculator.memory.fetch(variable_name)
    end

    def update(data)
      calculator.memory.update(data)
    end

    def []=(variable_name, value)
      calculator.memory[variable_name] = value
    end
  end
end
