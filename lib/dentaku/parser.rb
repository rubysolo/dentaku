require_relative './ast'

module Dentaku
  class Parser
    attr_reader :input, :output, :operations, :arities

    def initialize(tokens)
      @input      = tokens.dup
      @output     = []
      @operations = []
      @arities    = []
    end

    def get_args(count)
      Array.new(count) { output.pop }.reverse
    end

    def consume(count=2)
      operator = operations.pop
      output.push operator.new(*get_args(operator.arity || count))
    end

    def parse
      return AST::Nil.new if input.empty?

      while token = input.shift
        case token.category
        when :numeric
          output.push AST::Numeric.new(token)

        when :logical
          output.push AST::Logical.new(token)

        when :string
          output.push AST::String.new(token)

        when :identifier
          output.push AST::Identifier.new(token)

        when :operator, :comparator, :combinator
          op_class = operation(token)

          if op_class.right_associative?
            while operations.last && operations.last < AST::Operation && op_class.precedence < operations.last.precedence
              consume
            end

            operations.push op_class
          else
            while operations.last && operations.last < AST::Operation && op_class.precedence <= operations.last.precedence
              consume
            end

            operations.push op_class
          end

        when :function
          arities.push 0
          operations.push function(token)

        when :grouping
          case token.value
          when :open
            if input.first && input.first.value == :close
              input.shift
              consume(0)
            else
              operations.push AST::Grouping
            end

          when :close
            while operations.any? && operations.last != AST::Grouping
              consume
            end

            lparen = operations.pop
            fail "Unbalanced parenthesis" unless lparen == AST::Grouping

            if operations.last && operations.last < AST::Function
              consume(arities.pop.succ)
            end

          when :comma
            arities[-1] += 1
            while operations.any? && operations.last != AST::Grouping
              consume
            end

          else
            fail "Unknown grouping token #{ token.value }"
          end

        else
          fail "Not implemented for tokens of category #{ token.category }"
        end
      end

      while operations.any?
        consume
      end

      unless output.count == 1
        fail "Parse error"
      end

      output.first
    end

    def operation(token)
      {
        add:      AST::Addition,
        subtract: AST::Subtraction,
        multiply: AST::Multiplication,
        divide:   AST::Division,
        pow:      AST::Exponentiation,
        negate:   AST::Negation,
        mod:      AST::Modulo,

        lt:       AST::LessThan,
        gt:       AST::GreaterThan,
        le:       AST::LessThanOrEqual,
        ge:       AST::GreaterThanOrEqual,
        ne:       AST::NotEqual,
        eq:       AST::Equal,

        and:      AST::And,
        or:       AST::Or,
      }.fetch(token.value)
    end

    def function(token)
      Dentaku::AST::Function.get(token.value)
    end
  end
end
