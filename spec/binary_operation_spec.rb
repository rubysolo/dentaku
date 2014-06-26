require 'dentaku/binary_operation'

describe Dentaku::BinaryOperation do
  let(:operation) { described_class.new(2, 3) }
  let(:logical)   { described_class.new(true, false) }

  it 'raises a number to a power' do
    expect(operation.pow).to eq [:numeric, 8]
  end

  it 'adds two numbers' do
    expect(operation.add).to eq [:numeric, 5]
  end

  it 'subtracts two numbers' do
    expect(operation.subtract).to eq [:numeric, -1]
  end

  it 'multiplies two numbers' do
    expect(operation.multiply).to eq [:numeric, 6]
  end

  it 'divides two numbers' do
    expect(operation.divide).to eq [:numeric, (BigDecimal.new('2.0')/BigDecimal.new('3.0'))]
  end

  it 'compares two numbers' do
    expect(operation.le).to eq [:logical, true]
    expect(operation.lt).to eq [:logical, true]
    expect(operation.ne).to eq [:logical, true]

    expect(operation.ge).to eq [:logical, false]
    expect(operation.gt).to eq [:logical, false]
    expect(operation.eq).to eq [:logical, false]
  end

  it 'performs logical AND and OR' do
    expect(logical.and).to eq [:logical, false]
    expect(logical.or).to  eq [:logical, true]
  end

  it 'mods two numbers' do
    expect(operation.mod).to eq [:numeric, 2%3]
  end
end
