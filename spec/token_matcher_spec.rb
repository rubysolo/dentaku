require 'spec_helper'
require 'dentaku/token_matcher'

describe Dentaku::TokenMatcher do
  it 'with single category should match token category' do
    matcher = described_class.new(:numeric)
    token   = Dentaku::Token.new(:numeric, 5)

    matcher.should == token
  end

  it 'with multiple categories should match any included token category' do
    matcher    = described_class.new([:comparator, :operator])
    numeric    = Dentaku::Token.new(:numeric, 5)
    comparator = Dentaku::Token.new(:comparator, :lt)
    operator   = Dentaku::Token.new(:operator, :add)

    matcher.should == comparator
    matcher.should == operator
    matcher.should_not == numeric
  end

  it 'with single category and value should match token category and value' do
    matcher     = described_class.new(:operator, :add)
    addition    = Dentaku::Token.new(:operator, :add)
    subtraction = Dentaku::Token.new(:operator, :subtract)

    matcher.should == addition
    matcher.should_not == subtraction
  end

  it 'with multiple values should match any included token value' do
    matcher = described_class.new(:operator, [:add, :subtract])
    add = Dentaku::Token.new(:operator, :add)
    sub = Dentaku::Token.new(:operator, :subtract)
    mul = Dentaku::Token.new(:operator, :multiply)
    div = Dentaku::Token.new(:operator, :divide)

    matcher.should == add
    matcher.should == sub
    matcher.should_not == mul
    matcher.should_not == div
  end

  it 'should be invertible' do
    matcher = described_class.new(:operator, [:add, :subtract]).invert
    add = Dentaku::Token.new(:operator, :add)
    mul = Dentaku::Token.new(:operator, :multiply)
    cmp = Dentaku::Token.new(:comparator, :lt)

    matcher.should_not == add
    matcher.should == mul
    matcher.should == cmp
  end

  describe 'stream matching' do
    let(:stream) { token_stream(5, 11, 9, 24, :hello, 8) }

    describe :standard do
      let(:standard) { described_class.new(:numeric) }

      it 'should match zero or more occurrences in a token stream' do
        substream = standard.match(stream)
        substream.should be_matched
        substream.length.should eq 1
        substream.map(&:value).should eq [5]

        substream = standard.match(stream, 4)
        substream.should be_empty
        substream.should_not be_matched
      end
    end

    describe :star do
      let(:star) { described_class.new(:numeric).star }

      it 'should match zero or more occurrences in a token stream' do
        substream = star.match(stream)
        substream.should be_matched
        substream.length.should eq 4
        substream.map(&:value).should eq [5, 11, 9, 24]

        substream = star.match(stream, 4)
        substream.should be_empty
        substream.should be_matched
      end
    end

    describe :plus do
      let(:plus) { described_class.new(:numeric).plus }

      it 'should match one or more occurrences in a token stream' do
        substream = plus.match(stream)
        substream.should be_matched
        substream.length.should eq 4
        substream.map(&:value).should eq [5, 11, 9, 24]

        substream = plus.match(stream, 4)
        substream.should be_empty
        substream.should_not be_matched
      end
    end
  end
end

