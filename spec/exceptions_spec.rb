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
