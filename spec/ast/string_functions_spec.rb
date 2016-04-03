require 'spec_helper'
require 'dentaku/ast/functions/string_functions'

describe Dentaku::AST::StringFunctions::Left do
  let(:string) { identifier('string') }
  let(:length) { identifier('length') }

  subject { described_class.new(string, length) }

  it 'returns the left N characters of the string' do
    expect(subject.value('string' => 'ABCDEFG', 'length' => 4)).to eq 'ABCD'
  end

  it 'works correctly with literals' do
    left = literal('ABCD')
    len  = literal(2)
    fn   = described_class.new(left, len)
    expect(fn.value).to eq 'AB'
  end

  it 'handles an empty string correctly' do
    expect(subject.value('string' => '', 'length' => 4)).to eq ''
  end

  it 'handles size greater than input string length correctly' do
    expect(subject.value('string' => 'abcdefg', 'length' => 40)).to eq 'abcdefg'
  end
end

describe Dentaku::AST::StringFunctions::Right do
  it 'returns the right N characters of the string' do
    subject = described_class.new(literal('ABCDEFG'), literal(4))
    expect(subject.value).to eq 'DEFG'
  end

  it 'handles an empty string correctly' do
    subject = described_class.new(literal(''), literal(4))
    expect(subject.value).to eq ''
  end

  it 'handles size greater than input string length correctly' do
    subject = described_class.new(literal('abcdefg'), literal(40))
    expect(subject.value).to eq 'abcdefg'
  end
end

describe Dentaku::AST::StringFunctions::Mid do
  it 'returns a substring from the middle of the string' do
    subject = described_class.new(literal('ABCDEFG'), literal(4), literal(2))
    expect(subject.value).to eq 'DE'
  end

  it 'handles an empty string correctly' do
    subject = described_class.new(literal(''), literal(4), literal(2))
    expect(subject.value).to eq ''
  end

  it 'handles offset greater than input string length correctly' do
    subject = described_class.new(literal('abcdefg'), literal(40), literal(4))
    expect(subject.value).to eq ''
  end

  it 'handles size greater than input string length correctly' do
    subject = described_class.new(literal('abcdefg'), literal(4), literal(40))
    expect(subject.value).to eq 'defg'
  end
end

describe Dentaku::AST::StringFunctions::Len do
  it 'returns the length of a string' do
    subject = described_class.new(literal('ABCDEFG'))
    expect(subject.value).to eq 7
  end

  it 'handles an empty string correctly' do
    subject = described_class.new(literal(''))
    expect(subject.value).to eq 0
  end
end

describe Dentaku::AST::StringFunctions::Find do
  it 'returns the position of a substring within a string' do
    subject = described_class.new(literal('DE'), literal('ABCDEFG'))
    expect(subject.value).to eq 4
  end

  it 'handles an empty substring correctly' do
    subject = described_class.new(literal(''), literal('ABCDEFG'))
    expect(subject.value).to eq 1
  end

  it 'handles an empty string correctly' do
    subject = described_class.new(literal('DE'), literal(''))
    expect(subject.value).to be_nil
  end
end

describe Dentaku::AST::StringFunctions::Substitute do
  it 'replaces a substring within a string' do
    subject = described_class.new(literal('ABCDEFG'), literal('DE'), literal('xy'))
    expect(subject.value).to eq 'ABCxyFG'
  end

  it 'handles an empty search string correctly' do
    subject = described_class.new(literal('ABCDEFG'), literal(''), literal('xy'))
    expect(subject.value).to eq 'xyABCDEFG'
  end

  it 'handles an empty replacement string correctly' do
    subject = described_class.new(literal('ABCDEFG'), literal('DE'), literal(''))
    expect(subject.value).to eq 'ABCFG'
  end
end

describe Dentaku::AST::StringFunctions::Concat do
  it 'concatenates two strings' do
    subject = described_class.new(literal('ABC'), literal('DEF'))
    expect(subject.value).to eq 'ABCDEF'
  end

  it 'concatenates a string onto an empty string' do
    subject = described_class.new(literal(''), literal('ABC'))
    expect(subject.value).to eq 'ABC'
  end

  it 'concatenates an empty string onto a string' do
    subject = described_class.new(literal('ABC'), literal(''))
    expect(subject.value).to eq 'ABC'
  end

  it 'concatenates two empty strings' do
    subject = described_class.new(literal(''), literal(''))
    expect(subject.value).to eq ''
  end
end
