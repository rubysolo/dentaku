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
    calculator.evaluate('(1+1+1)/3*100').should eq(100)
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

  it 'should accept digits in identifiers' do
    calculator.evaluate('foo1 * 2', :foo1 => 2).should eq(4)
    calculator.evaluate('foo1 * 2', 'foo1' => 4).should eq(8)
    calculator.evaluate('1foo * 2', '1foo' => 2).should eq(4)
    calculator.evaluate('fo1o * 2', :fo1o => 4).should eq(8)
  end

  it 'should compare string literals with string variables' do
    calculator.evaluate('fruit = "apple"', :fruit => 'apple').should be_true
    calculator.evaluate('fruit = "apple"', :fruit => 'pear').should be_false
  end

  it 'should do case-sensitive comparison' do
    calculator.evaluate('fruit = "Apple"', :fruit => 'apple').should be_false
    calculator.evaluate('fruit = "Apple"', :fruit => 'Apple').should be_true
  end

  it 'should allow binding logical values' do
    calculator.evaluate('some_boolean AND 7 > 5', :some_boolean => true).should be_true
    calculator.evaluate('some_boolean AND 7 < 5', :some_boolean => true).should be_false
    calculator.evaluate('some_boolean AND 7 > 5', :some_boolean => false).should be_false

    calculator.evaluate('some_boolean OR 7 > 5', :some_boolean => true).should be_true
    calculator.evaluate('some_boolean OR 7 < 5', :some_boolean => true).should be_true
    calculator.evaluate('some_boolean OR 7 < 5', :some_boolean => false).should be_false

  end

  describe 'functions' do
    it 'should include IF' do
      calculator.evaluate('if(foo < 8, 10, 20)', :foo => 2).should eq(10)
      calculator.evaluate('if(foo < 8, 10, 20)', :foo => 9).should eq(20)
      calculator.evaluate('if (foo < 8, 10, 20)', :foo => 2).should eq(10)
      calculator.evaluate('if (foo < 8, 10, 20)', :foo => 9).should eq(20)
    end

    it 'should include ROUND' do
      calculator.evaluate('round(8.2)').should eq(8)
      calculator.evaluate('round(8.8)').should eq(9)
      calculator.evaluate('round(8.75, 1)').should eq(BigDecimal.new('8.8'))

      calculator.evaluate('ROUND(apples * 0.93)', { :apples => 10 }).should eq(9)
    end

    it 'should include NOT' do
      calculator.evaluate('NOT(some_boolean)', :some_boolean => true).should be_false
      calculator.evaluate('NOT(some_boolean)', :some_boolean => false).should be_true

      calculator.evaluate('NOT(some_boolean) AND 7 > 5', :some_boolean => true).should be_false
      calculator.evaluate('NOT(some_boolean) OR 7 < 5', :some_boolean => false).should be_true
    end
  end
end
