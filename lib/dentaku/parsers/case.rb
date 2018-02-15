module Dentaku
  module Parsers
    class Case
      attr_reader :parser

      def initialize(parser)
        @parser = parser
      end

      def parse(token, output)
        case token.value
        when :open
          parse_open(token, output)
        when :close
          parse_close(token, output)
        when :when
          parse_when(token, output)
        when :then
          parse_then(token, output)
        when :else
          parse_else
        else
          raise ParseError.for("Unknown case token #{ token.value }", token_name: token.value)
        end
      end

      def parse_open(token, output)
        # special handling for case nesting: strip out inner case
        # statements and parse their AST segments recursively
        if parser.operations.include?(AST::Case)
          open_cases = 0
          case_end_index = nil

          parser.input.each_with_index do |token, index|
            if token.category == :case && token.value == :open
              open_cases += 1
            end

            if token.category == :case && token.value == :close
              if open_cases > 0
                open_cases -= 1
              else
                case_end_index = index
                break
              end
            end
          end

          inner_case_inputs = parser.input.slice!(0..case_end_index)

          subparser = Parser.new(
            inner_case_inputs,
            operations: [AST::Case],
            arities: [0]
          )

          subparser.parse
          output.concat(subparser.output)
        else
          parser.operations.push AST::Case
          parser.arities.push(0)
        end
      end

      def parse_close(token, output)
        if parser.operations[1] == AST::CaseThen
          while parser.operations.last != AST::Case
            parser.consume
          end

          parser.operations.push(AST::CaseConditional)
          parser.consume(2)
          parser.arities[-1] += 1
        elsif parser.operations[1] == AST::CaseElse
          while parser.operations.last != AST::Case
            parser.consume
          end

          parser.arities[-1] += 1
        end

        unless parser.operations.count == 1 && parser.operations.last == AST::Case
          fail! :unprocessed_token, token_name: token.value
        end

        parser.consume(parser.arities.pop.succ)
      end

      def parse_when(token, output)
        if parser.operations[1] == AST::CaseThen
          while ![AST::CaseWhen, AST::Case].include?(parser.operations.last)
            parser.consume
          end

          parser.operations.push(AST::CaseConditional)
          parser.consume(2)
          parser.arities[-1] += 1
        elsif parser.operations.last == AST::Case
          parser.operations.push(AST::CaseSwitchVariable)
          parser.consume
        end

        parser.operations.push(AST::CaseWhen)
      end

      def parse_then(token, output)
        if parser.operations[1] == AST::CaseWhen
          while ![AST::CaseThen, AST::Case].include?(parser.operations.last)
            parser.consume
          end
        end

        parser.operations.push(AST::CaseThen)
      end

      def parse_else
        if parser.operations[1] == AST::CaseThen
          while parser.operations.last != AST::Case
            parser.consume
          end

          parser.operations.push(AST::CaseConditional)
          parser.consume(2)
          parser.arities[-1] += 1
        end

        parser.operations.push(AST::CaseElse)
      end
    end
  end
end
