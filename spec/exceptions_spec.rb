require 'spec_helper'
require 'dentaku/exceptions'

describe Dentaku::UnboundVariableError do
  it 'includes variable name(s) in message' do
    exception = described_class.new(['length'])
    expect(exception.unbound_variables).to include('length')
  end
end

describe Dentaku::Error do
  it 'is included in every Dentaku exception, even those subclassing Ruby built-ins' do
    [
      Dentaku::UnboundVariableError.new(['x']),
      Dentaku::MathDomainError.new(:asin, [2]),
      Dentaku::NodeError.new(:numeric, :string, :left),
      Dentaku::ParseError.for(:node_invalid),
      Dentaku::TokenizerError.for(:parse_error),
      Dentaku::ArgumentError.for(:invalid_value),
      Dentaku::ZeroDivisionError.new,
    ].each do |exception|
      expect(exception).to be_a(described_class)
    end
  end

  it 'preserves stdlib ancestry for exceptions subclassing Ruby built-ins' do
    expect(Dentaku::ArgumentError.for(:invalid_value)).to be_a(::ArgumentError)
    expect(Dentaku::ZeroDivisionError.new).to be_a(::ZeroDivisionError)
  end
end

describe Dentaku::ParseError do
  it 'builds a message from reason and metadata' do
    exception = described_class.for(:too_few_operands, operator: 'Dentaku::AST::Addition', expected: 2, actual: 1)
    expect(exception.message).to eq('Dentaku::AST::Addition has too few operands (given 1, expected 2)')
  end

  it 'constructs with sparse metadata' do
    expect(described_class.for(:node_invalid).message).to eq('Node is invalid')
  end

  it 'describes an :incompatible expectation as requiring compatible operands' do
    exception = described_class.for(:node_invalid, operator: 'Dentaku::AST::Addition', expected: :incompatible, actual: :string)
    expect(exception.message).to eq('Dentaku::AST::Addition requires compatible operands, but got string')
  end

  it 'allows call sites to override the default message' do
    expect {
      raise described_class.for(:node_invalid), 'Case missing switch variable'
    }.to raise_error(described_class, 'Case missing switch variable')
  end
end

describe Dentaku::TokenizerError do
  it 'builds a message from reason and metadata' do
    exception = described_class.for(:parse_error, at: '$5')
    expect(exception.message).to eq("parse error at: '$5'")
  end
end
