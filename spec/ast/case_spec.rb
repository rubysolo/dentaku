require 'spec_helper'
require 'dentaku/ast/operation'
require 'dentaku/ast/logical'
require 'dentaku/ast/identifier'
require 'dentaku/ast/arithmetic'
require 'dentaku/ast/case'

require 'dentaku/token'

describe Dentaku::AST::Case do
  let!(:one) { Dentaku::AST::Logical.new Dentaku::Token.new(:numeric, 1) }
  let!(:two)  { Dentaku::AST::Logical.new Dentaku::Token.new(:numeric, 2) }
  let!(:apple) do
    Dentaku::AST::Logical.new Dentaku::Token.new(:string, 'apple')
  end
  let!(:banana) do
    Dentaku::AST::Logical.new Dentaku::Token.new(:string, 'banana')
  end
  let!(:identifier) do
    Dentaku::AST::Identifier.new(Dentaku::Token.new(:identifier, :fruit))
  end
  let!(:switch) { Dentaku::AST::CaseSwitchVariable.new(identifier) }

  let!(:when1) { Dentaku::AST::CaseWhen.new(apple) }
  let!(:then1) { Dentaku::AST::CaseThen.new(one) }
  let!(:conditional1) { Dentaku::AST::CaseConditional.new(when1, then1) }

  let!(:when2) { Dentaku::AST::CaseWhen.new(banana) }
  let!(:then2) { Dentaku::AST::CaseThen.new(two) }
  let!(:conditional2) { Dentaku::AST::CaseConditional.new(when2, then2) }

  describe '#value' do
    it 'raises an exception if there is no switch variable' do
      expect { described_class.new(conditional1, conditional2) }
        .to raise_error('Case missing switch variable')
    end

    it 'raises an exception if a non-conditional is passed' do
      expect { described_class.new(switch, conditional1, when2) }
        .to raise_error(/is not a CaseConditional/)
    end

    it 'tests each conditional against the switch variable' do
      node = described_class.new(switch, conditional1, conditional2)
      expect(node.value(fruit: 'banana')).to eq(2)
    end

    it 'raises an exception if the conditional is not matched' do
      node = described_class.new(switch, conditional1, conditional2)
      expect { node.value(fruit: 'orange') }
        .to raise_error("No block matched the switch value 'orange'")
    end

    it 'uses the else value if provided and conditional is not matched' do
      three = Dentaku::AST::Logical.new Dentaku::Token.new(:numeric, 3)
      else_statement = Dentaku::AST::CaseElse.new(three)
      node = described_class.new(
        switch,
        conditional1,
        conditional2,
        else_statement)
      expect(node.value(fruit: 'orange')).to eq(3)
    end
  end

  describe '#dependencies' do
    let!(:tax) do
      Dentaku::AST::Identifier.new(Dentaku::Token.new(:identifier, :tax))
    end
    let!(:fallback) do
      Dentaku::AST::Identifier.new(Dentaku::Token.new(:identifier, :fallback))
    end
    let!(:addition) { Dentaku::AST::Addition.new(two, tax) }
    let!(:when2) { Dentaku::AST::CaseWhen.new(banana) }
    let!(:then2) { Dentaku::AST::CaseThen.new(addition) }
    let!(:else2) { Dentaku::AST::CaseElse.new(fallback) }
    let!(:conditional2) { Dentaku::AST::CaseConditional.new(when2, then2) }

    it 'gathers dependencies from switch and conditionals' do
      node = described_class.new(switch, conditional1, conditional2, else2)
      expect(node.dependencies).to eq([:fruit, :tax, :fallback])
    end
  end
end
