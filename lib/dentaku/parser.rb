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
      @skip_indices      = []
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

      if (output_size > max_size && operations.empty?) || args_size > max_size
        expect = min_size == max_size ? min_size : min_size..max_size
        fail! :too_many_operands, operator: operator, expect: expect, actual: output_size
      end

      args = []
      if operator == AST::Array && output.empty?
        # special case: empty array literal '{}'
        output.push(operator.new)
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

      i = 0
      while i < input.length
        if @skip_indices.include?(i)
          i += 1
          next
        end
        token = input[i]
        lookahead = input[i + 1]
        process_token(token, lookahead, i, input)
        i += 1
      end

      consume while operations.any?

      fail! :invalid_statement unless output.count == 1

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

    def process_token(token, lookahead, index, tokens)
      case token.category
      when :datetime      then output << AST::DateTime.new(token)
      when :numeric       then output << AST::Numeric.new(token)
      when :logical       then output << AST::Logical.new(token)
      when :string        then output << AST::String.new(token)
      when :identifier    then output << AST::Identifier.new(token, case_sensitive: case_sensitive)
      when :operator, :comparator, :combinator
        handle_operator(token, lookahead)
      when :null
        output << AST::Nil.new
      when :function
        handle_function(token)
      when :case
        handle_case(token)
      when :access
        handle_access(token)
      when :array
        handle_array(token)
      when :grouping
        handle_grouping(token, lookahead, tokens)
      else
        fail! :not_implemented_token_category, token_category: token.category
      end
    end

    def handle_operator(token, lookahead)
      op_class = operation(token).resolve_class(lookahead)
      if op_class.right_associative?
        consume while operations.last && operations.last < AST::Operation && op_class.precedence < operations.last.precedence
      else
        consume while operations.last && operations.last < AST::Operation && op_class.precedence <= operations.last.precedence
      end
      operations.push op_class
    end

    def handle_function(token)
      func = function(token)
      fail! :undefined_function, function_name: token.value if func.nil?
      arities.push 0
      operations.push func
    end

    def handle_case(token)
      # We always operate on the innermost (most recent) CASE on the stack.
      case_index = operations.rindex(AST::Case) || -1
      token_index = case_index + 1

      case token.value
      when :open
        # Start a new CASE context.
        operations.push AST::Case
        arities.push(0)

      when :close
        # Finalize any trailing THEN/ELSE expression still on the stack.
        if operations[token_index] == AST::CaseThen
          consume_until(AST::Case)
          operations.push(AST::CaseConditional)
          consume(2)
          arities[-1] += 1
        elsif operations[token_index] == AST::CaseElse
          consume_until(AST::Case)
          arities[-1] += 1
        end
        fail! :unprocessed_token, token_name: token.value unless operations.last == AST::Case
        consume(arities.pop.succ)

      when :when
        if operations[token_index] == AST::CaseThen
          # Close out previous WHEN/THEN pair.
          consume_until([AST::CaseWhen, AST::Case])
          operations.push(AST::CaseConditional)
          consume(2)
          arities[-1] += 1
        elsif operations.last == AST::Case
          # First WHEN: finalize switch variable expression.
          operations.push(AST::CaseSwitchVariable)
          consume
        end
        operations.push(AST::CaseWhen)

      when :then
        if operations[token_index] == AST::CaseWhen
          consume_until([AST::CaseThen, AST::Case])
        end
        operations.push(AST::CaseThen)

      when :else
        if operations[token_index] == AST::CaseThen
          consume_until(AST::Case)
          operations.push(AST::CaseConditional)
          consume(2)
          arities[-1] += 1
        end
        operations.push(AST::CaseElse)

      else
        fail! :unknown_case_token, token_name: token.value
      end
    end

    def consume_until(target)
      matcher =
        case target
        when Array then ->(op) { target.include?(op) }
        else ->(op) { op == target }
        end

      consume while operations.any? && !matcher.call(operations.last)
    end

    def handle_access(token)
      case token.value
      when :lbracket
        operations.push AST::Access

      when :rbracket
        consume while operations.any? && operations.last != AST::Access
        fail! :unbalanced_bracket, token: token unless operations.last == AST::Access
        consume
      end
    end

    def handle_array(token)
      case token.value
      when :array_start
        operations.push AST::Array
        arities.push 0

      when :array_end
        consume while operations.any? && operations.last != AST::Array
        fail! :unbalanced_bracket, token: token unless operations.last == AST::Array
        consume(arities.pop.succ)
      end
    end

    def handle_grouping(token, lookahead, tokens)
      case token.value
      when :open
        if lookahead && lookahead.value == :close
          # empty grouping (e.g. function with zero arguments) — we trigger consume later
          # skip to the end
          lookahead_index = tokens.index(lookahead)
          @skip_indices << lookahead_index if lookahead_index
          arities.pop
          consume(0)
        else
          operations.push AST::Grouping
        end

      when :close
        consume while operations.any? && operations.last != AST::Grouping
        lparen = operations.pop
        fail! :unbalanced_parenthesis, token unless lparen == AST::Grouping
        if operations.last && operations.last < AST::Function
          consume(arities.pop.succ)
        end

      when :comma
        fail! :invalid_statement if arities.empty?
        arities[-1] += 1
        consume while operations.any? && operations.last != AST::Grouping && operations.last != AST::Array

      else
        fail! :unknown_grouping_token, token_name: token.value
      end
    end

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
