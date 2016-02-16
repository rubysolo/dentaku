require 'spec_helper'
require 'dentaku/ast/arithmetic'

require 'dentaku/token'

describe Dentaku::AST::Addition do
  let(:five) { Dentaku::AST::Logical.new Dentaku::Token.new(:numeric, 5) }
  let(:six)  { Dentaku::AST::Logical.new Dentaku::Token.new(:numeric, 6) }

  let(:t)    { Dentaku::AST::Numeric.new Dentaku::Token.new(:logical, true) }

  it 'performs addition' do
    node = described_class.new(five, six)
    expect(node.value).to eq 11
  end

  it 'requires numeric operands' do
    expect {
      described_class.new(five, t)
    }.to raise_error(Dentaku::ParseError, /requires numeric operands/)

    expression = Dentaku::AST::Multiplication.new(five, five)
    group = Dentaku::AST::Grouping.new(expression)

    expect {
      described_class.new(group, five)
    }.not_to raise_error
  end
end
