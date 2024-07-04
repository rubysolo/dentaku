require 'spec_helper'
require 'set'

class TestVisitor
  attr_reader :visited

  def initialize(node)
    @visited = Set.new
    node.accept(self)
  end

  def mark_visited(node)
    @visited.add(node.class.to_s.split("::").last.to_sym)
  end

  def visit_operation(node)
    mark_visited(node)

    node.left.accept(self) if node.left
    node.right.accept(self) if node.right
  end

  def visit_function(node)
    mark_visited(node)
    node.args.each { |a| a.accept(self) }
  end

  def visit_array(node)
    mark_visited(node)
  end

  def visit_case(node)
    mark_visited(node)
    node.switch.accept(self)
    node.conditions.each { |c| c.accept(self) }
    node.else && node.else.accept(self)
  end

  def visit_switch(node)
    mark_visited(node)
    node.node.accept(self)
  end

  def visit_case_conditional(node)
    mark_visited(node)
    node.when.accept(self)
    node.then.accept(self)
  end

  def visit_when(node)
    mark_visited(node)
    node.node.accept(self)
  end

  def visit_then(node)
    mark_visited(node)
    node.node.accept(self)
  end

  def visit_else(node)
    mark_visited(node)
    node.node.accept(self)
  end

  def visit_negation(node)
    mark_visited(node)
    node.node.accept(self)
  end

  def visit_access(node)
    mark_visited(node)
    node.structure.accept(self)
    node.index.accept(self)
  end

  def visit_literal(node)
    mark_visited(node)
  end

  def visit_identifier(node)
    mark_visited(node)
  end

  def visit_nil(node)
    mark_visited(node)
  end
end

describe TestVisitor do
  def generic_subclasses
    [
      :Arithmetic,
      :Bitwise,
      :Combinator,
      :Comparator,
      :Function,
      :FunctionRegistry,
      :Grouping,
      :Literal,
      :Node,
      :Operation,
      :StringFunctions,
      :RubyMath,
      :Enum,
    ]
  end

  it 'visits all concrete AST node types' do
    @visited = Set.new

    visit_nodes('(1 + 7) * (8 ^ 2) / - 3.0 - apples * 5%')
    visit_nodes('1 < 2 and 3 <= 4 or 5 > 6 AND 7 >= 8 OR 9 != 10 and true')
    visit_nodes('IF(a[0] = NULL, "five", \'seven\')')
    visit_nodes('case (a % 5) when 0 then a else b end')
    visit_nodes('0xCAFE & (0xDECAF << 3) | (0xBEEF >> 5)')
    visit_nodes('2017-12-24 23:59:59')
    visit_nodes('ALL({1, 2, 3}, val, val % 2 == 0)')
    visit_nodes('ANY(vals, val, val > 1)')
    visit_nodes('COUNT({1, 2, 3})')
    visit_nodes('PLUCK(users, age)')
    visit_nodes('XOR(false, false)')
    visit_nodes('duration(1, day)')
    visit_nodes('MAP(vals, val, val + 1)')
    visit_nodes('FILTER(vals, val, val > 1)')
    visit_nodes('REDUCE(vals, memo, val, memo + val)')

    @expected = Set.new(Dentaku::AST::constants - generic_subclasses)
    expect(@visited.sort).to eq(@expected.sort)
  end

  private

  def visit_nodes(string)
    tokens = Dentaku::Tokenizer.new.tokenize(string)
    node = Dentaku::Parser.new(tokens).parse
    visitor = TestVisitor.new(node)
    @visited += visitor.visited
  end
end
