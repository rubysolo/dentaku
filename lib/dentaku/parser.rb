require_relative './ast'

module Dentaku
  class Parser
    AST_OPERATIONS = {
      add:      AST::Addition,
      subtract: AST::Subtraction,
      multiply: AST::Multiplication,
      divide:   AST::Division,
      pow:      AST::Exponentiation,
      negate:   AST::Negation,
      mod:      AST::Modulo,

      bitor:    AST::BitwiseOr,
      bitand:   AST::BitwiseAnd,
      bitshiftleft:  AST::BitwiseShiftLeft,
      bitshiftright: AST::BitwiseShiftRight,

      lt:       AST::LessThan,
      gt:       AST::GreaterThan,
      le:       AST::LessThanOrEqual,
      ge:       AST::GreaterThanOrEqual,
      ne:       AST::NotEqual,
      eq:       AST::Equal,

      and:      AST::And,
      or:       AST::Or,
      xor:      AST::Xor,
    }.freeze

    attr_reader :input, :output, :operations, :arities, :case_sensitive

    def initialize(tokens, options = {})
      @input             = tokens.dup
      @output            = []
      @operations        = options.fetch(:operations, [])
      @arities           = options.fetch(:arities, [])
      @function_registry = options.fetch(:function_registry, nil)
      @case_sensitive    = options.fetch(:case_sensitive, false)
    end

    def consume(count = 2)
      operator = operations.pop
      fail! :invalid_statement if operator.nil?

      output_size = output.length
      args_size = operator.arity || count
      min_size = operator.arity || operator.min_param_count || count
      max_size = operator.arity || operator.max_param_count || count

      if output_size < min_size || args_size < min_size
        expect = min_size == max_size ? min_size : min_size..max_size
        fail! :too_few_operands, operator: operator, expect: expect, actual: output_size
      end

      if output_size > max_size && operations.empty? || args_size > max_size
        expect = min_size == max_size ? min_size : min_size..max_size
        fail! :too_many_operands, operator: operator, expect: expect, actual: output_size
      end

      if operator == AST::Array && output.empty?
        output.push(operator.new())
      else
        fail! :invalid_statement if output_size < args_size
        args = Array.new(args_size) { output.pop }.reverse

        output.push operator.new(*args)
      end

      if operator.respond_to?(:callback) && !operator.callback.nil?
        operator.callback.call(args)
      end
    rescue ::ArgumentError => e
      raise Dentaku::ArgumentError, e.message
    rescue NodeError => e
      fail! :node_invalid, operator: operator, child: e.child, expect: e.expect, actual: e.actual
    end

    def parse
      return AST::Nil.new if input.empty?

      while token = input.shift
        case token.category
        when :datetime
          output.push AST::DateTime.new(token)

        when :numeric
          output.push AST::Numeric.new(token)

        when :logical
          output.push AST::Logical.new(token)

        when :string
          output.push AST::String.new(token)

        when :identifier
          output.push AST::Identifier.new(token, case_sensitive: case_sensitive)

        when :operator, :comparator, :combinator
          op_class = operation(token)
          op_class = op_class.resolve_class(input.first)

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
          func = function(token)
          if func.nil?
            fail! :undefined_function, function_name: token.value
          end

          arities.push 0
          operations.push func

        when :case
          case_index = operations.index { |o| o == AST::Case } || -1
          token_index = case_index + 1

          case token.value
          when :open
            # special handling for case nesting: strip out inner case
            # statements and parse their AST segments recursively
            if operations.include?(AST::Case)
              open_cases = 0
              case_end_index = nil

              input.each_with_index do |input_token, index|
                if input_token.category == :case
                  if input_token.value == :open
                    open_cases += 1
                  end

                  if input_token.value == :close
                    if open_cases > 0
                      open_cases -= 1
                    else
                      case_end_index = index
                      break
                    end
                  end
                end
              end
              inner_case_inputs = input.slice!(0..case_end_index)
              subparser = Parser.new(
                inner_case_inputs,
                operations: [AST::Case],
                arities: [0],
                function_registry: @function_registry,
                case_sensitive: case_sensitive
              )
              subparser.parse
              output.concat(subparser.output)
            else
              operations.push AST::Case
              arities.push(0)
            end
          when :close
            if operations[token_index] == AST::CaseThen
              while operations.last != AST::Case
                consume
              end

              operations.push(AST::CaseConditional)
              consume(2)
              arities[-1] += 1
            elsif operations[token_index] == AST::CaseElse
              while operations.last != AST::Case
                consume
              end

              arities[-1] += 1
            end

            unless operations.count >= 1 && operations.last == AST::Case
              fail! :unprocessed_token, token_name: token.value
            end
            consume(arities.pop.succ)
          when :when
            if operations[token_index] == AST::CaseThen
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
            if operations[token_index] == AST::CaseWhen
              while ![AST::CaseThen, AST::Case].include?(operations.last)
                consume
              end
            end
            operations.push(AST::CaseThen)
          when :else
            if operations[token_index] == AST::CaseThen
              while operations.last != AST::Case
                consume
              end

              operations.push(AST::CaseConditional)
              consume(2)
              arities[-1] += 1
            end

            operations.push(AST::CaseElse)
          else
            fail! :unknown_case_token, token_name: token.value
          end

        when :access
          case token.value
          when :lbracket
            operations.push AST::Access
          when :rbracket
            while operations.any? && operations.last != AST::Access
              consume
            end

            unless operations.last == AST::Access
              fail! :unbalanced_bracket, token: token
            end
            consume
          end

        when :array
          case token.value
          when :array_start
            operations.push AST::Array
            arities.push 0
          when :array_end
            while operations.any? && operations.last != AST::Array
              consume
            end

            unless operations.last == AST::Array
              fail! :unbalanced_bracket, token: token
            end

            consume(arities.pop.succ)
          end

        when :grouping
          case token.value
          when :open
            if input.first && input.first.value == :close
              input.shift
              arities.pop
              consume(0)
            else
              operations.push AST::Grouping
            end

          when :close
            while operations.any? && operations.last != AST::Grouping
              consume
            end

            lparen = operations.pop
            unless lparen == AST::Grouping
              fail! :unbalanced_parenthesis, token
            end

            if operations.last && operations.last < AST::Function
              consume(arities.pop.succ)
            end

          when :comma
            fail! :invalid_statement if arities.empty?
            arities[-1] += 1
            while operations.any? && operations.last != AST::Grouping && operations.last != AST::Array
              consume
            end

          else
            fail! :unknown_grouping_token, token_name: token.value
          end

        else
          fail! :not_implemented_token_category, token_category: token.category
        end
      end

      while operations.any?
        consume
      end

      unless output.count == 1
        fail! :invalid_statement
      end

      output.first
    end

    def operation(token)
      AST_OPERATIONS.fetch(token.value)
    end

    def function(token)
      function_registry.get(token.value)
    end

    def function_registry
      @function_registry ||= Dentaku::AST::FunctionRegistry.new
    end

    private

    def fail!(reason, **meta)
      message =
        case reason
        when :node_invalid
          "#{meta.fetch(:operator)} requires #{meta.fetch(:expect).join(', ')} operands, but got #{meta.fetch(:actual)}"
        when :too_few_operands
          "#{meta.fetch(:operator)} has too few operands (given #{meta.fetch(:actual)}, expected #{meta.fetch(:expect)})"
        when :too_many_operands
          "#{meta.fetch(:operator)} has too many operands (given #{meta.fetch(:actual)}, expected #{meta.fetch(:expect)})"
        when :undefined_function
          "Undefined function #{meta.fetch(:function_name)}"
        when :unprocessed_token
          "Unprocessed token #{meta.fetch(:token_name)}"
        when :unknown_case_token
          "Unknown case token #{meta.fetch(:token_name)}"
        when :unbalanced_bracket
          "Unbalanced bracket"
        when :unbalanced_parenthesis
          "Unbalanced parenthesis"
        when :unknown_grouping_token
          "Unknown grouping token #{meta.fetch(:token_name)}"
        when :not_implemented_token_category
          "Not implemented for tokens of category #{meta.fetch(:token_category)}"
        when :invalid_statement
          "Invalid statement"
        else
          raise ::ArgumentError, "Unhandled #{reason}"
        end

      raise ParseError.for(reason, **meta), message
    end
  end
end
