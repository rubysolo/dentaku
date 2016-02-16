require_relative './ast'

module Dentaku
  class Parser
    attr_reader :input, :output, :operations, :arities

    def initialize(tokens, options={})
      @input      = tokens.dup
      @output     = []
      @operations = options.fetch(:operations, [])
      @arities    = options.fetch(:arities, [])
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

        when :null
          output.push AST::Nil.new

        when :function
          arities.push 0
          operations.push function(token)

        when :case
          case token.value
          when :open
            # special handling for case nesting: strip out inner case
            # statements and parse their AST segments recursively
            if operations.include?(AST::Case)
              last_case_close_index = nil
              first_nested_case_close_index = nil
              input.each_with_index do |token, index|
                first_nested_case_close_index = last_case_close_index
                if token.category == :case && token.value == :close
                  last_case_close_index = index
                end
              end
              inner_case_inputs = input.slice!(0..first_nested_case_close_index)
              subparser = Parser.new(
                inner_case_inputs,
                operations: [AST::Case],
                arities: [0]
              )
              subparser.parse
              output.concat(subparser.output)
            else
              operations.push AST::Case
              arities.push(0)
            end
          when :close
            if operations[1] == AST::CaseThen
              while operations.last != AST::Case
                consume
              end

              operations.push(AST::CaseConditional)
              consume(2)
              arities[-1] += 1
            elsif operations[1] == AST::CaseElse
              while operations.last != AST::Case
                consume
              end

              arities[-1] += 1
            end

            unless operations.count == 1 && operations.last == AST::Case
              fail ParseError, "Unprocessed token #{ token.value }"
            end
            consume(arities.pop.succ)
          when :when
            if operations[1] == AST::CaseThen
              while ![AST::CaseWhen, AST::Case].include?(operations.last)
                consume
              end
              operations.push(AST::CaseConditional)
              consume(2)
              arities[-1] += 1
            elsif operations.last == AST::Case
              operations.push(AST::CaseSwitchVariable)
              consume
            end

            operations.push(AST::CaseWhen)
          when :then
            if operations[1] == AST::CaseWhen
              while ![AST::CaseThen, AST::Case].include?(operations.last)
                consume
              end
            end
            operations.push(AST::CaseThen)
          when :else
            if operations[1] == AST::CaseThen
              while operations.last != AST::Case
                consume
              end

              operations.push(AST::CaseConditional)
              consume(2)
              arities[-1] += 1
            end

            operations.push(AST::CaseElse)
          else
            fail ParseError, "Unknown case token #{ token.value }"
          end

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
            fail ParseError, "Unbalanced parenthesis" unless lparen == AST::Grouping

            if operations.last && operations.last < AST::Function
              consume(arities.pop.succ)
            end

          when :comma
            arities[-1] += 1
            while operations.any? && operations.last != AST::Grouping
              consume
            end

          else
            fail ParseError, "Unknown grouping token #{ token.value }"
          end

        else
          fail ParseError, "Not implemented for tokens of category #{ token.category }"
        end
      end

      while operations.any?
        consume
      end

      unless output.count == 1
        fail ParseError, "Invalid statement"
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
