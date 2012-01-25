require 'dentaku/calculator'

describe Dentaku::Calculator do
  let(:calculator)  { described_class.new }
  let(:with_memory) { described_class.new.store(:apples => 3) }

  it 'evaluates an expression' do
    calculator.evaluate('7+3').should eq(10)
  end

  describe 'memory' do
    it { calculator.should be_empty }
    it { with_memory.should_not be_empty   }
    it { with_memory.clear.should be_empty }

    it { with_memory.memory(:apples).should eq(3) }
    it { with_memory.memory('apples').should eq(3) }

    it { calculator.store(:apples, 3).memory('apples').should eq(3) }
    it { calculator.store('apples', 3).memory(:apples).should eq(3) }

    it 'should discard local values' do
      calculator.evaluate('pears * 2', :pears => 5).should eq(10)
      calculator.should be_empty
      lambda { calculator.tokenize('pears * 2') }.should raise_error
    end
  end

  it 'should evaluate a statement with no variables' do
    calculator.evaluate('5+3').should eq(8)
  end

  it 'should fail to evaluate unbound statements' do
    lambda { calculator.evaluate('foo * 1.5') }.should raise_error
  end

  it 'should evaluate unbound statements given a binding in memory' do
    calculator.evaluate('foo * 1.5', :foo => 2).should eq(3)
    calculator.bind(:monkeys => 3).evaluate('monkeys < 7').should be_true
    calculator.evaluate('monkeys / 1.5').should eq(2)
  end

  it 'should rebind for each evaluation' do
    calculator.evaluate('foo * 2', :foo => 2).should eq(4)
    calculator.evaluate('foo * 2', :foo => 4).should eq(8)
  end

  it 'should accept strings or symbols for binding keys' do
    calculator.evaluate('foo * 2', :foo => 2).should eq(4)
    calculator.evaluate('foo * 2', 'foo' => 4).should eq(8)
  end

  describe 'functions' do
    it 'should include IF' do
      calculator.evaluate('if (foo < 8, 10, 20)', :foo => 2).should eq(10)
      calculator.evaluate('if (foo < 8, 10, 20)', :foo => 9).should eq(20)
    end
  end
end
