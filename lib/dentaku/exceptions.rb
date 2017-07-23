module Dentaku
  class UnboundVariableError < StandardError
    attr_accessor :recipient_variable

    attr_reader :unbound_variables

    def initialize(unbound_variables)
      @unbound_variables = unbound_variables
    end
  end

  class NodeError < StandardError
    attr_reader :child, :expect, :actual

    def initialize(expect, actual, child)
      @expect = Array(expect)
      @actual = actual
      @child = child
    end
  end

  class ParseError < StandardError
    attr_reader :reason, :meta

    def initialize(reason, **meta)
      @reason = reason
      @meta = meta
    end
  end

  class TokenizerError < StandardError
    attr_reader :reason, :meta

    def initialize(reason, **meta)
      @reason = reason
      @meta = meta
    end
  end

  class ArgumentError < ::ArgumentError
    attr_reader :reason, :meta

    def initialize(reason, **meta)
      @reason = reason
      @meta = meta
    end
  end

  class ZeroDivisionError < ::ZeroDivisionError
    attr_accessor :recipient_variable
  end
end
