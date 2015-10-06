require 'spec_helper'
require 'dentaku/ast/node'
require 'dentaku/tokenizer'
require 'dentaku/parser'

describe Dentaku::AST::Node do
  it 'returns list of dependencies' do
    node = make_node('x + 5')
    expect(node.dependencies).to eq ['x']

    node = make_node('5 < x')
    expect(node.dependencies).to eq ['x']

    node = make_node('5 < 7')
    expect(node.dependencies).to eq []

    node = make_node('(y * 7)')
    expect(node.dependencies).to eq ['y']

    node = make_node('if(x > 5, y, z)')
    expect(node.dependencies).to eq ['x', 'y', 'z']

    node = make_node('if(x > 5, y, z)')
    expect(node.dependencies('x' => 7)).to eq ['y', 'z']

    node = make_node('')
    expect(node.dependencies).to eq []
  end

  it 'returns unique list of dependencies' do
    node = make_node('x + x')
    expect(node.dependencies).to eq ['x']
  end

  private

  def make_node(expression)
    Dentaku::Parser.new(Dentaku::Tokenizer.new.tokenize(expression)).parse
  end
end
