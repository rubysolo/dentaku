require 'spec_helper'
require 'dentaku/evaluator'

describe Dentaku::Evaluator do
  let(:evaluator) { Dentaku::Evaluator.new }

  describe 'rule scanning' do
    it 'should find a matching rule' do
      rule   = [Dentaku::TokenMatcher.new(:numeric, nil)]
      stream = [Dentaku::Token.new(:numeric, 1), Dentaku::Token.new(:operator, :add), Dentaku::Token.new(:numeric, 1)]
      position, _match = evaluator.find_rule_match(rule, stream)
      position.should eq(0)
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

    it 'supports unary minus' do
      evaluator.evaluate(token_stream(:subtract, 1)).should eq(-1)
      evaluator.evaluate(token_stream(1, :subtract, :subtract, 1)).should eq(2)
    end

    it 'supports unary percentage' do
      evaluator.evaluate(token_stream(50, :mod)).should eq(0.5)
      evaluator.evaluate(token_stream(50, :mod, :multiply, 100)).should eq(50)
    end

    describe 'maths' do
      it 'should perform addition' do
        evaluator.evaluate(token_stream(1, :add, 1)).should eq(2)
      end

      it 'should respect order of precedence' do
        evaluator.evaluate(token_stream(1, :add, 1, :multiply, 5)).should eq(6)
        evaluator.evaluate(token_stream(2, :add, 10, :mod, 2)).should eq(2)
      end

      it 'should respect explicit grouping' do
        evaluator.evaluate(token_stream(:open, 1, :add, 1, :close, :multiply, 5)).should eq(10)
      end

      it 'should return floating point from division when there is a remainder' do
        evaluator.evaluate(token_stream(5, :divide, 4)).should eq(1.25)
      end
    end

    describe 'functions' do
      it 'should be evaluated' do
        evaluator.evaluate(token_stream(:round,     :open, 5, :divide, 3.0, :close)).should eq 2
        evaluator.evaluate(token_stream(:round,     :open, 5, :divide, 3.0, :comma, 2, :close)).should eq 1.67
        evaluator.evaluate(token_stream(:roundup,   :open, 5, :divide, 1.2, :close)).should eq 5
        evaluator.evaluate(token_stream(:rounddown, :open, 5, :divide, 1.2, :close)).should eq 4
      end
    end

    describe 'logic' do
      it 'should evaluate conditional' do
        evaluator.evaluate(token_stream(5, :gt, 1)).should be_true
      end

      it 'should expand inequality ranges' do
        stream   = token_stream(5, :lt, 10, :le, 10)
        expected = token_stream(5, :lt, 10, :and, 10, :le, 10)
        evaluator.evaluate_step(stream, 0, 5, :expand_range).should eq(expected)

        evaluator.evaluate(token_stream(5, :lt, 10, :le, 10)).should be_true
        evaluator.evaluate(token_stream(3, :gt,  5, :ge,  1)).should be_false

        lambda { evaluator.evaluate(token_stream(3, :gt,  2, :lt,   1)) }.should raise_error
      end

      it 'should evaluate combined conditionals' do
        evaluator.evaluate(token_stream(5, :gt, 1, :or, :false)).should be_true
        evaluator.evaluate(token_stream(5, :gt, 1, :and, :false)).should be_false
      end

      it 'should support negation of a logical value' do
        evaluator.evaluate(token_stream(:not, :open, 5, :gt, 1, :or,  :false, :close)).should be_false
        evaluator.evaluate(token_stream(:not, :open, 5, :gt, 1, :and, :false, :close)).should be_true
      end
    end
  end
end
