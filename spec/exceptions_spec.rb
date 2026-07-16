require 'spec_helper'
require 'dentaku/exceptions'

describe Dentaku::UnboundVariableError do
  it 'includes variable name(s) in message' do
    exception = described_class.new(['length'])
    expect(exception.unbound_variables).to include('length')
  end
end

describe Dentaku::ParseError do
  describe '.for' do
    it 'raises an ArgumentError for an unknown reason' do
      expect {
        described_class.for(:not_a_real_reason)
      }.to raise_error(::ArgumentError, /Unhandled not_a_real_reason/)
    end

    it 'stores the reason and meta' do
      error = described_class.for(:undefined_function, function_name: 'FOO')
      expect(error.reason).to eq(:undefined_function)
      expect(error.meta).to eq(function_name: 'FOO')
    end

    it 'uses a provided message instead of the default' do
      error = described_class.for(:node_invalid, 'custom message')
      expect(error.message).to eq('custom message')
    end

    it 'cannot be instantiated directly with new' do
      expect {
        described_class.new(:invalid_statement)
      }.to raise_error(NoMethodError)
    end
  end

  describe 'default messages' do
    def message_for(reason, **meta)
      described_class.for(reason, **meta).message
    end

    it 'describes incompatible operands for node_invalid' do
      expect(message_for(:node_invalid, operator: 'Dentaku::AST::Addition', expect: :incompatible, actual: 'string'))
        .to eq('Dentaku::AST::Addition requires operands that are numeric or compatible types, not string')
    end

    it 'describes numeric operands for node_invalid' do
      expect(message_for(:node_invalid, operator: 'Op', expect: :numeric, actual: 'string'))
        .to eq('Op requires numeric operands, not string')
    end

    it 'describes logical operands for node_invalid' do
      expect(message_for(:node_invalid, operator: 'Op', expect: :logical, actual: 'numeric'))
        .to eq('Op requires logical operands, not numeric')
    end

    it 'falls back to listing expectations for other node_invalid types' do
      expect(message_for(:node_invalid, operator: 'Op', expect: [:datetime, :duration], actual: 'string'))
        .to eq('Op requires datetime, duration operands, not string')
    end

    it 'uses a generic message when node_invalid meta is incomplete' do
      expect(message_for(:node_invalid)).to eq('Invalid node')
    end

    it 'builds a too_few_operands message' do
      expect(message_for(:too_few_operands, operator: 'IF', actual: 1, expect: 3))
        .to eq('IF has too few operands (given 1, expected 3)')
    end

    it 'builds a too_many_operands message' do
      expect(message_for(:too_many_operands, operator: 'IF', actual: 4, expect: 3))
        .to eq('IF has too many operands (given 4, expected 3)')
    end

    it 'builds an undefined_function message' do
      expect(message_for(:undefined_function, function_name: 'FOO'))
        .to eq('Undefined function FOO')
    end

    it 'builds an unprocessed_token message' do
      expect(message_for(:unprocessed_token, token_name: 'foo')).to eq('Unprocessed token foo')
    end

    it 'builds an unknown_case_token message' do
      expect(message_for(:unknown_case_token, token_name: 'foo')).to eq('Unknown case token foo')
    end

    it 'builds an unbalanced_bracket message' do
      expect(message_for(:unbalanced_bracket)).to eq('Unbalanced bracket')
    end

    it 'builds an unbalanced_parenthesis message' do
      expect(message_for(:unbalanced_parenthesis)).to eq('Unbalanced parenthesis')
    end

    it 'builds an unknown_grouping_token message' do
      expect(message_for(:unknown_grouping_token, token_name: 'foo')).to eq('Unknown grouping token foo')
    end

    it 'builds a not_implemented_token_category message' do
      expect(message_for(:not_implemented_token_category, token_category: 'foo'))
        .to eq('Not implemented for tokens of category foo')
    end

    it 'builds an invalid_statement message' do
      expect(message_for(:invalid_statement)).to eq('Invalid statement')
    end
  end
end
