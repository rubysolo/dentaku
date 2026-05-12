require 'dentaku/print_visitor'

module Dentaku
  # Visits an AST and produces a natural-language English representation of
  # the expression. Operators are verbalized (`>=` -> "is greater than or
  # equal to"), logical combinators are spaced as words, and identifiers can
  # optionally be substituted with concrete values.
  #
  #   ast = Dentaku::Calculator.new.ast("days >= min AND days <= max")
  #   Dentaku::HumanizeVisitor.new(ast, min: 5, max: 20).to_s
  #   # => "days is greater than or equal to 5 and days is less than or equal to 20"
  #
  # Falls back to PrintVisitor behavior for nodes without a verbal mapping, so
  # any expression that PrintVisitor handles is also handled here.
  class HumanizeVisitor < PrintVisitor
    OPERATOR_PHRASES = {
      Dentaku::AST::Addition           => 'plus',
      Dentaku::AST::Subtraction        => 'minus',
      Dentaku::AST::Multiplication     => 'times',
      Dentaku::AST::Division           => 'divided by',
      Dentaku::AST::Modulo             => 'modulo',
      Dentaku::AST::Exponentiation     => 'to the power of',
      Dentaku::AST::Equal              => 'equals',
      Dentaku::AST::NotEqual           => 'does not equal',
      Dentaku::AST::LessThan           => 'is less than',
      Dentaku::AST::LessThanOrEqual    => 'is less than or equal to',
      Dentaku::AST::GreaterThan        => 'is greater than',
      Dentaku::AST::GreaterThanOrEqual => 'is greater than or equal to',
      Dentaku::AST::And                => 'and',
      Dentaku::AST::Or                 => 'or',
      Dentaku::AST::BitwiseAnd         => 'bitwise and',
      Dentaku::AST::BitwiseOr          => 'bitwise or',
      Dentaku::AST::BitwiseShiftLeft   => 'shifted left by',
      Dentaku::AST::BitwiseShiftRight  => 'shifted right by',
    }.freeze

    def initialize(node, values = {})
      @values = values.each_with_object({}) { |(k, v), h| h[k.to_s] = v }
      super(node)
    end

    def visit_operation(node)
      phrase = OPERATOR_PHRASES[node.class]
      return super unless phrase

      visit_operand(node.left, node.class.precedence, suffix: ' ', dir: :left) if node.left
      @output << phrase
      visit_operand(node.right, node.class.precedence, prefix: ' ', dir: :right) if node.right
    end

    def visit_negation(node)
      @output << 'negative '
      node.node.accept(self)
    end

    def visit_nil(_node)
      @output << 'null'
    end

    def visit_identifier(node)
      if @values.key?(node.identifier)
        value = @values[node.identifier]
        @output << (value.is_a?(::String) ? value.inspect : value.to_s)
      else
        super
      end
    end
  end
end
