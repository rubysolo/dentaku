require 'spec_helper'
require 'dentaku/evaluator'

describe Dentaku::Evaluator do
  let(:evaluator) { Dentaku::Evaluator.new }

  describe 'rule scanning' do
    it 'finds a matching rule' do
      rule   = [Dentaku::TokenMatcher.new(:numeric, nil)]
      stream = [Dentaku::Token.new(:numeric, 1), Dentaku::Token.new(:operator, :add), Dentaku::Token.new(:numeric, 1)]
      position, _match = evaluator.find_rule_match(rule, stream)
      expect(position).to eq(0)
    end
  end

  describe 'evaluating' do
    it 'empty expression is be truthy' do
      expect(evaluator.evaluate([])).to be
    end

    it 'empty expression equals 0' do
      expect(evaluator.evaluate([])).to eq(0)
    end

    it 'single numeric evaluates to its value' do
      expect(evaluator.evaluate([Dentaku::Token.new(:numeric, 10)])).to eq(10)
      expect(evaluator.evaluate([Dentaku::Token.new(:string,  'a')])).to eq('a')
    end

    it 'evaluates one apply step' do
      stream   = token_stream(1, :add, 1, :add, 1)
      expected = token_stream(2, :add, 1)

      expect(evaluator.evaluate_step(stream, 0, 3, :apply)).to eq(expected)
    end

    it 'evaluates one grouping step' do
      stream   = token_stream(:open, 1, :add, 1, :close, :multiply, 5)
      expected = token_stream(2, :multiply, 5)

      expect(evaluator.evaluate_step(stream, 0, 5, :evaluate_group)).to eq(expected)
    end

    it 'supports unary minus' do
      expect(evaluator.evaluate(token_stream(:subtract, 1))).to eq(-1)
      expect(evaluator.evaluate(token_stream(1, :subtract, :subtract, 1))).to eq(2)
    end

    it 'supports unary percentage' do
      expect(evaluator.evaluate(token_stream(50, :mod))).to eq(0.5)
      expect(evaluator.evaluate(token_stream(50, :mod, :multiply, 100))).to eq(50)
    end

    describe 'maths' do
      it 'performs addition' do
        expect(evaluator.evaluate(token_stream(1, :add, 1))).to eq(2)
      end

      it 'respects order of precedence' do
        expect(evaluator.evaluate(token_stream(1, :add, 1, :multiply, 5))).to eq(6)
        expect(evaluator.evaluate(token_stream(2, :add, 10, :mod, 2))).to eq(2)
      end

      it 'respects explicit grouping' do
        expect(evaluator.evaluate(token_stream(:open, 1, :add, 1, :close, :multiply, 5))).to eq(10)
      end

      it 'returns floating point from division when there is a remainder' do
        expect(evaluator.evaluate(token_stream(5, :divide, 4))).to eq(1.25)
      end
    end

    describe 'functions' do
      it 'is evaluated' do
        expect(evaluator.evaluate(token_stream(:round,     :open, 5, :divide, 3.0, :close))).to eq 2
        expect(evaluator.evaluate(token_stream(:round,     :open, 5, :divide, 3.0, :comma, 2, :close))).to eq 1.67
        expect(evaluator.evaluate(token_stream(:roundup,   :open, 5, :divide, 1.2, :close))).to eq 5
        expect(evaluator.evaluate(token_stream(:rounddown, :open, 5, :divide, 1.2, :close))).to eq 4
      end
    end

    describe 'logic' do
      it 'evaluates conditional' do
        expect(evaluator.evaluate(token_stream(5, :gt, 1))).to be_truthy
      end

      it 'expands inequality ranges' do
        stream   = token_stream(5, :lt, 10, :le, 10)
        expected = token_stream(5, :lt, 10, :and, 10, :le, 10)
        expect(evaluator.evaluate_step(stream, 0, 5, :expand_range)).to eq(expected)

        expect(evaluator.evaluate(token_stream(5, :lt, 10, :le, 10))).to be_truthy
        expect(evaluator.evaluate(token_stream(3, :gt,  5, :ge,  1))).to be_falsey

        expect { evaluator.evaluate(token_stream(3, :gt,  2, :lt,   1)) }.to raise_error
      end

      it 'evaluates combined conditionals' do
        expect(evaluator.evaluate(token_stream(5, :gt, 1, :or, :false))).to be_truthy
        expect(evaluator.evaluate(token_stream(5, :gt, 1, :and, :false))).to be_falsey
      end

      it 'negates a logical value' do
        expect(evaluator.evaluate(token_stream(:not, :open, 5, :gt, 1, :or,  :false, :close))).to be_falsey
        expect(evaluator.evaluate(token_stream(:not, :open, 5, :gt, 1, :and, :false, :close))).to be_truthy
      end
    end
  end
end
