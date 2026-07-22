require 'dentaku/print_visitor'

module Dentaku
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

    MATH_PHRASES = {
      'SIN'    => [:unary,        'sine of'],
      'COS'    => [:unary,        'cosine of'],
      'TAN'    => [:unary,        'tangent of'],
      'ASIN'   => [:unary,        'arcsine of'],
      'ACOS'   => [:unary,        'arccosine of'],
      'ATAN'   => [:unary,        'arctangent of'],
      'SINH'   => [:unary,        'hyperbolic sine of'],
      'COSH'   => [:unary,        'hyperbolic cosine of'],
      'TANH'   => [:unary,        'hyperbolic tangent of'],
      'ASINH'  => [:unary,        'inverse hyperbolic sine of'],
      'ACOSH'  => [:unary,        'inverse hyperbolic cosine of'],
      'ATANH'  => [:unary,        'inverse hyperbolic tangent of'],
      'EXP'    => [:unary,        'e to the power of'],
      'LOG2'   => [:unary,        'log base 2 of'],
      'LOG10'  => [:unary,        'log base 10 of'],
      'SQRT'   => [:unary,        'square root of'],
      'CBRT'   => [:unary,        'cube root of'],
      'ERF'    => [:unary,        'error function of'],
      'ERFC'   => [:unary,        'complementary error function of'],
      'GAMMA'  => [:unary,        'gamma function of'],
      'LGAMMA' => [:unary,        'log-gamma of'],
      'FREXP'  => [:unary,        'mantissa and exponent of'],
      'ATAN2'  => [:binary_and,   'arctangent of'],
      'HYPOT'  => [:binary_and,   'hypotenuse of'],
      'LDEXP'  => [:binary_infix, 'times 2 to the power of'],
      'LOG'    => [:log,          'logarithm of'],
    }.freeze

    def initialize(node, values = {})
      @values = values.each_with_object({}) { |(k, v), h| h[k.to_s] = v }
      super(node)
    end

    def visit_operation(node)
      phrase = OPERATOR_PHRASES[node.class]
      return super unless phrase

      visit_operand(node.left,  node.class.precedence, suffix: ' ', dir: :left)  if node.left
      @output << phrase
      visit_operand(node.right, node.class.precedence, prefix: ' ', dir: :right) if node.right
    end

    def visit_function(node)
      case node.name.to_s.upcase
      when 'IF'        then humanize_if(node)
      when 'AND'       then humanize_join(node.args, 'and')
      when 'OR'        then humanize_join(node.args, 'or')
      when 'XOR'       then humanize_join(node.args, 'exclusive-or')
      when 'NOT'       then @output << 'not '; node.args[0].accept(self)
      when 'SWITCH'    then humanize_switch(node)
      when 'MIN'       then humanize_aggregate(node.args, 'minimum of')
      when 'MAX'       then humanize_aggregate(node.args, 'maximum of')
      when 'SUM'       then humanize_aggregate(node.args, 'sum of')
      when 'AVG'       then humanize_aggregate(node.args, 'average of')
      when 'COUNT'     then humanize_aggregate(node.args, 'count of')
      when 'ABS'       then @output << 'absolute value of '; node.args[0].accept(self)
      when 'ROUND'     then humanize_round(node, 'rounded')
      when 'ROUNDUP'   then humanize_round(node, 'rounded up')
      when 'ROUNDDOWN' then humanize_round(node, 'rounded down')
      when 'INTERCEPT'
        @output << 'linear intercept of '
        node.args[0].accept(self); @output << ' and '; node.args[1].accept(self)
      when 'LEFT'
        @output << 'first '; node.args[1].accept(self)
        @output << ' characters of '; node.args[0].accept(self)
      when 'RIGHT'
        @output << 'last '; node.args[1].accept(self)
        @output << ' characters of '; node.args[0].accept(self)
      when 'MID'
        node.args[2].accept(self)
        @output << ' characters of '; node.args[0].accept(self)
        @output << ' starting at position '; node.args[1].accept(self)
      when 'LEN'
        @output << 'length of '; node.args[0].accept(self)
      when 'FIND'
        @output << 'position of '; node.args[0].accept(self)
        @output << ' in '; node.args[1].accept(self)
      when 'SUBSTITUTE'
        node.args[0].accept(self)
        @output << ' with '; node.args[1].accept(self)
        @output << ' replaced by '; node.args[2].accept(self)
      when 'CONCAT'    then humanize_concat(node.args)
      when 'CONTAINS'
        node.args[1].accept(self); @output << ' contains '; node.args[0].accept(self)
      when 'MAP'       then humanize_enum(node, 'for each', 'in', ': ')
      when 'FILTER'    then humanize_enum(node, 'filter', 'in', ' where ')
      when 'ALL'       then humanize_enum(node, 'all', 'in', ' satisfy ')
      when 'ANY'       then humanize_enum(node, 'any', 'in', ' satisfies ')
      when 'PLUCK'     then humanize_pluck(node)
      else
        humanize_math(node) || super
      end
    end

    def visit_case(node)
      node.switch.accept(self)
      @output << ' case:'
      node.conditions.each { |c| c.accept(self) }
      node.else&.accept(self)
    end

    def visit_switch(node)
      node.node.accept(self)
    end

    def visit_case_conditional(node)
      @output << ' when '
      node.when.node.accept(self)
      @output << ' then '
      node.then.node.accept(self)
    end

    def visit_else(node)
      @output << '; otherwise '
      node.node.accept(self)
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

    private

    def humanize_if(node)
      @output << 'if '
      node.predicate.accept(self)
      @output << ' then '
      node.left.accept(self)
      @output << ' else '
      node.right.accept(self)
    end

    def humanize_join(args, conjunction)
      args.each_with_index do |arg, i|
        @output << " #{conjunction} " if i > 0
        arg.accept(self)
      end
    end

    def humanize_aggregate(args, prefix)
      @output << prefix
      args.each_with_index do |arg, i|
        @output << (i == 0 ? ' ' : ', ')
        arg.accept(self)
      end
    end

    def humanize_round(node, word)
      node.args[0].accept(self)
      @output << " #{word} to "
      node.args[1] ? node.args[1].accept(self) : (@output << '0')
      @output << ' decimal places'
    end

    def humanize_concat(args)
      args.each_with_index do |arg, i|
        @output << (i == args.length - 1 && i > 0 ? ' and ' : ', ') if i > 0
        arg.accept(self)
      end
      @output << ' joined'
    end

    def humanize_enum(node, verb, preposition, separator)
      collection, item, expr = node.args
      @output << "#{verb} "
      item.accept(self)
      @output << " #{preposition} "
      collection.accept(self)
      @output << separator
      expr.accept(self)
    end

    def humanize_pluck(node)
      @output << 'values of '
      node.args[1].accept(self)
      @output << ' from '
      node.args[0].accept(self)
      if node.args[2]
        @output << ' (default: '; node.args[2].accept(self); @output << ')'
      end
    end

    def humanize_switch(node)
      args        = node.args
      rest        = args[1..]
      has_default = rest.length.odd?
      pairs       = has_default ? rest[0..-2] : rest
      pair_count  = pairs.length / 2

      args[0].accept(self)
      @output << ' switch:'
      pairs.each_slice(2).with_index do |(match, result), idx|
        @output << ' when '; match.accept(self)
        @output << ' use ';  result.accept(self)
        @output << ';' if has_default || idx < pair_count - 1
      end
      if has_default
        @output << ' otherwise '; rest.last.accept(self)
      end
    end

    def humanize_math(node)
      style, phrase = MATH_PHRASES[node.name.to_s.upcase]
      return nil unless phrase

      case style
      when :unary
        @output << "#{phrase} "; node.args[0].accept(self)
      when :binary_and
        @output << "#{phrase} "
        node.args[0].accept(self); @output << ' and '; node.args[1].accept(self)
      when :binary_infix
        node.args[0].accept(self); @output << " #{phrase} "; node.args[1].accept(self)
      when :log
        @output << "#{phrase} "
        node.args[0].accept(self)
        if node.args[1]
          @output << ' in base '; node.args[1].accept(self)
        end
      end
      true
    end
  end
end
