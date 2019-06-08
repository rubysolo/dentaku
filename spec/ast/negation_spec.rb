require 'spec_helper'
require 'dentaku/ast/arithmetic'

require 'dentaku/token'

describe Dentaku::AST::Negation do
  let(:five) { Dentaku::AST::Logical.new Dentaku::Token.new(:numeric, 5) }
  let(:t)    { Dentaku::AST::Numeric.new Dentaku::Token.new(:logical, true) }

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
end
