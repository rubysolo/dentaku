require 'spec_helper'
require 'dentaku/evaluator'

describe Dentaku::Evaluator do
  let(:evaluator) { Dentaku::Evaluator.new }

  describe 'rule scanning' do
    it 'should find a matching rule' do
      rule   = [Dentaku::Token.new(:numeric, nil)]
      stream = [Dentaku::Token.new(:numeric, 1), Dentaku::Token.new(:operator, :add), Dentaku::Token.new(:numeric, 1)]
      evaluator.find_rule_match(rule, stream).should eq(0)
    end
  end

  describe 'evaluating' do
    it 'empty expression should be truthy' do
      evaluator.evaluate([]).should be
    end

    it 'empty expression should equal 0' do
      evaluator.evaluate([]).should eq(0)
    end

    it 'single numeric should return value' do
      evaluator.evaluate([Dentaku::Token.new(:numeric, 10)]).should eq(10)
      evaluator.evaluate([Dentaku::Token.new(:string,  'a')]).should eq('a')
    end

    it 'should evaluate one apply step' do
      stream   = token_stream(1, :add, 1, :add, 1)
      expected = token_stream(2, :add, 1)

      evaluator.evaluate_step(stream, 0, 3, :apply).should eq(expected)
    end

    it 'should evaluate one grouping step' do
      stream   = token_stream(:open, 1, :add, 1, :close, :multiply, 5)
      expected = token_stream(2, :multiply, 5)

      evaluator.evaluate_step(stream, 0, 5, :evaluate_group).should eq(expected)
    end

    describe 'maths' do
      it 'should perform addition' do
        evaluator.evaluate(token_stream(1, :add, 1)).should eq(2)
      end

      it 'should respect order of precedence' do
        evaluator.evaluate(token_stream(1, :add, 1, :multiply, 5)).should eq(6)
      end

      it 'should respect explicit grouping' do
        evaluator.evaluate(token_stream(:open, 1, :add, 1, :close, :multiply, 5)).should eq(10)
      end
    end

    describe 'logic' do
      it 'should evaluate conditional' do
        evaluator.evaluate(token_stream(5, :gt, 1)).should be_true
      end

      it 'should evaluate combined conditionals' do
        evaluator.evaluate(token_stream(5, :gt, 1, :or, :false)).should be_true
        evaluator.evaluate(token_stream(5, :gt, 1, :and, :false)).should be_false
      end
    end
  end
end
