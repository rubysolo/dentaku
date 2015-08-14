require 'spec_helper'
require 'dentaku/ast/numeric'

require 'dentaku/token'

describe Dentaku::AST::Numeric do
  subject { described_class.new(Dentaku::Token.new(:numeric, 5)) }

  it 'has numeric type' do
    expect(subject.type).to eq :numeric
  end

  it 'has no dependencies' do
    expect(subject.dependencies).to be_empty
  end
end
