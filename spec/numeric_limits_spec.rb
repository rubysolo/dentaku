require 'spec_helper'
require 'dentaku'

# Ruby does bignum arithmetic in single C calls that Timeout can't interrupt,
# so one short formula could otherwise tie up a thread for hours.
describe 'numeric size limits' do
  let(:calculator) { Dentaku::Calculator.new }
  let(:max) { Dentaku::NumericLimits::MAX_DIGITS }

  def rejects(formula, **context)
    expect { calculator.evaluate!(formula, **context) }
      .to raise_error(Dentaku::ArgumentError, /more than #{max} digits/)
    expect(calculator.evaluate(formula, **context)).to be_nil
  end

  it 'still computes large numbers within the limit' do
    expect(calculator.evaluate!('2 ^ 33000')).to eq(2**33000)
    expect(calculator.evaluate!('7 ^ -2')).to eq(Rational(1, 49))
    expect(calculator.evaluate!('1 << 33000')).to eq(1 << 33000)
    expect(calculator.evaluate!('ROUND(1e9000)')).to eq(10**9000)
    expect(calculator.evaluate!('1.5 ^ 0.5')).to be_within(1e-12).of(Math.sqrt(1.5))
    expect(calculator.evaluate!('0 ^ 100000000')).to eq(0)
    expect(calculator.evaluate!('1 ^ 100000000')).to eq(1)
    expect(calculator.evaluate!('-1 ^ 100000001')).to eq(-1)
  end

  it 'rejects a power whose result would be too long' do
    rejects('2 ^ 40000')
    rejects('7 ^ 100000000')
    rejects('7 ^ -100000000')
    rejects('7 ^ 1e8')
    rejects('7.5 ^ 100000000')
    rejects('0xffffffff ^ 10000000')
    rejects('x ^ y', x: 7, y: 100_000_000)
  end

  it 'rejects a left shift whose result would be too long' do
    rejects('1 << 40000')
    rejects('1 << 10000000000')
  end

  it 'rejects arithmetic results that grow past the limit' do
    rejects('x * x', x: 10**6000)
    rejects('MUL(7 ^ 9000, 7 ^ 9000)')
    rejects('x | 1', x: 10**20000)
  end

  it 'rejects oversized numbers where they are used' do
    rejects('ROUND(1e20000)')
    rejects('ROUND(1e100000000, -2)')
    rejects('ROUNDUP(1e100000000)')
    rejects('ROUNDDOWN(1e100000000)')
    rejects('ROUND(1.5, 1e100000000)')
    rejects('LEFT("abc", 1e100000000)')
    rejects('MID("abc", 1e100000000, 1)')
    rejects('1e100000000 + 1')
    rejects('x + 1', x: '1e100000000')
  end
end
