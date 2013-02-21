require 'dentaku/binary_operation'

describe Dentaku::BinaryOperation do
  let(:operation) { described_class.new(2, 3) }
  let(:logical)   { described_class.new(true, false) }

  it 'raises a number to a power' do
    operation.pow.should eq [:numeric, 8]
  end

  it 'adds two numbers' do
    operation.add.should eq [:numeric, 5]
  end

  it 'subtracts two numbers' do
    operation.subtract.should eq [:numeric, -1]
  end

  it 'multiplies two numbers' do
    operation.multiply.should eq [:numeric, 6]
  end

  it 'divides two numbers' do
    operation.divide.should eq [:numeric, (2.0/3.0)]
  end

  it 'compares two numbers' do
    operation.le.should eq [:logical, true]
    operation.lt.should eq [:logical, true]
    operation.ne.should eq [:logical, true]

    operation.ge.should eq [:logical, false]
    operation.gt.should eq [:logical, false]
    operation.eq.should eq [:logical, false]
  end

  it 'performs logical AND and OR' do
    logical.and.should eq [:logical, false]
    logical.or.should  eq [:logical, true]
  end
end
