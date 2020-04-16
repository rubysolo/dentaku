require 'spec_helper'
require 'dentaku/ast/arithmetic'

require 'dentaku/token'

describe Dentaku::AST::Negation do
  let(:five) { Dentaku::AST::Numeric.new Dentaku::Token.new(:numeric, 5) }
  let(:t)    { Dentaku::AST::Logical.new Dentaku::Token.new(:logical, true) }
  let(:x)    { Dentaku::AST::Identifier.new Dentaku::Token.new(:identifier, 'x') }

  it 'allows access to its sub-node' do
    node = described_class.new(five)
    expect(node.node).to eq(five)
  end

  it 'performs negation' do
    node = described_class.new(five)
    expect(node.value).to eq(-5)
  end

  it 'requires numeric operands' do
    expect {
      described_class.new(t)
    }.to raise_error(Dentaku::NodeError, /requires numeric operands/)

    expression = Dentaku::AST::Negation.new(five)
    group = Dentaku::AST::Grouping.new(expression)

    expect {
      described_class.new(group)
    }.not_to raise_error
  end

  it 'correctly parses string operands to numeric values' do
    node = described_class.new(x)
    expect(node.value('x' => '5')).to eq(-5)
  end

  it 'raises error if input string is not coercible to numeric' do
    node = described_class.new(x)
    expect { node.value('x' => 'invalid') }.to raise_error(Dentaku::ArgumentError)
  end

  it 'raises error if given a non-numeric argument' do
    node = described_class.new(x)
    expect { node.value('x' => true) }.to raise_error(Dentaku::ArgumentError)
  end
end
