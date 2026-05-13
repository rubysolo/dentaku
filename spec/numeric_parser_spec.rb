require 'dentaku/numeric_parser'

describe Dentaku::NumericParser do
  it 'casts a String to an Integer if possible' do
    result = Dentaku::NumericParser.ensure_numeric!('3')
    expect(result).to eq(3)
    expect(result).to be_a(Integer)
  end

  it 'casts a String to a BigDecimal if possible and if Integer would loose information' do
    result = Dentaku::NumericParser.ensure_numeric!('3.2')
    expect(result).to eq(3.2)
    expect(result).to be_a(BigDecimal)
  end

  it 'casts a String to a BigDecimal with a negative number' do
    result = Dentaku::NumericParser.ensure_numeric!('-3.2')
    expect(result).to eq(-3.2)
    expect(result).to be_a(BigDecimal)
  end

  it 'casts a String to a BigDecimal without a leading zero' do
    result = Dentaku::NumericParser.ensure_numeric!('-.2')
    expect(result).to eq(-0.2)
    expect(result).to be_a(BigDecimal)
  end

  it 'casts a String with Sientific notiation to a BigDecimal' do
    result = Dentaku::NumericParser.ensure_numeric!('12E1')
    expect(result).to eq(12e1)
    expect(result).to be_a(BigDecimal)
  end

  it 'casts a String with negative Sientific notiation to a BigDecimal' do
    result = Dentaku::NumericParser.ensure_numeric!('12e-2')
    expect(result).to eq(0.12)
    expect(result).to be_a(BigDecimal)
  end

  it 'casts a String with hexadecimal to an Integer' do
    result1 = Dentaku::NumericParser.ensure_numeric!('0xFFD')
    result2 = Dentaku::NumericParser.ensure_numeric!('0x00000001')
    expect(result1).to eq(4093)
    expect(result2).to eq(1)
    expect(result1).to be_a(Integer)
    expect(result2).to be_a(Integer)
  end

  it 'casts a String with a negative hexadecimal to an Integer' do
    result = Dentaku::NumericParser.ensure_numeric!('-0xFF')
    expect(result).to eq(-0xFF)
    expect(result).to be_a(Integer)
  end

  it 'raises an error if the value could not be cast to a Numeric' do
    expect { Dentaku::NumericParser.ensure_numeric!('flarble') }.to raise_error Dentaku::ArgumentError
    expect { Dentaku::NumericParser.ensure_numeric!('-') }.to raise_error Dentaku::ArgumentError
    expect { Dentaku::NumericParser.ensure_numeric!('') }.to raise_error Dentaku::ArgumentError
    expect { Dentaku::NumericParser.ensure_numeric!(nil) }.to raise_error Dentaku::ArgumentError
    expect { Dentaku::NumericParser.ensure_numeric!('7.') }.to raise_error Dentaku::ArgumentError
    expect { Dentaku::NumericParser.ensure_numeric!(true) }.to raise_error Dentaku::ArgumentError
    expect { Dentaku::NumericParser.ensure_numeric!("1 - 2") }.to raise_error Dentaku::ArgumentError
    expect { Dentaku::NumericParser.ensure_numeric!([1]) }.to raise_error Dentaku::ArgumentError
    expect { Dentaku::NumericParser.ensure_numeric!("1f") }.to raise_error Dentaku::ArgumentError
  end
end
