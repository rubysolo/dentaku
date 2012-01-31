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
      stream   = ts(1, :add, 1, :add, 1)
      expected = ts(2, :add, 1)

      evaluator.evaluate_step(stream, 0, 3, :apply).should eq(expected)
    end

    it 'should evaluate one grouping step' do
      stream   = ts(:open, 1, :add, 1, :close, :multiply, 5)
      expected = ts(2, :multiply, 5)

      evaluator.evaluate_step(stream, 0, 5, :evaluate_group).should eq(expected)
    end

    describe 'maths' do
      it 'should perform addition' do
        evaluator.evaluate(ts(1, :add, 1)).should eq(2)
      end

      it 'should respect order of precedence' do
        evaluator.evaluate(ts(1, :add, 1, :multiply, 5)).should eq(6)
      end

      it 'should respect explicit grouping' do
        evaluator.evaluate(ts(:open, 1, :add, 1, :close, :multiply, 5)).should eq(10)
      end
    end

    describe 'logic' do
      it 'should evaluate conditional' do
        evaluator.evaluate(ts(5, :gt, 1)).should be_true
      end

      it 'should evaluate combined conditionals' do
        evaluator.evaluate(ts(5, :gt, 1, :or, :false)).should be_true
        evaluator.evaluate(ts(5, :gt, 1, :and, :false)).should be_false
      end
    end
  end

  private

  def ts(*args)
    args.map do |arg|
      category = (arg.is_a? Fixnum) ? :numeric : category_for(arg)
      arg = (arg == :true) if category == :logical
      Dentaku::Token.new(category, arg)
    end
  end

  def category_for(value)
    case value
    when Numeric
      :numeric
    when :add, :subtract, :multiply, :divide
      :operator
    when :open, :close
      :grouping
    when :le, :ge, :ne, :ne, :lt, :gt, :eq
      :comparator
    when :and, :or
      :combinator
    when :true, :false
      :logical
    else
      :identifier
    end
  end
end

