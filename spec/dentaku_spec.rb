require 'dentaku'

describe Dentaku do
  it 'evaulates an expression' do
    expect(Dentaku('5+3')).to eql(8)
  end

  it 'binds values to variables' do
    expect(Dentaku('oranges > 7', oranges: 10)).to be_truthy
  end

  it 'evaulates a nested function' do
    expect(Dentaku('roundup(roundup(3 * cherries) + raspberries)', cherries: 1.5, raspberries: 0.9)).to eql(6)
  end

  it 'treats variables as case-insensitive' do
    expect(Dentaku('40 + N', 'n' => 2)).to eql(42)
    expect(Dentaku('40 + N', 'N' => 2)).to eql(42)
    expect(Dentaku('40 + n', 'N' => 2)).to eql(42)
    expect(Dentaku('40 + n', 'n' => 2)).to eql(42)
  end

  it 'raises a parse error for bad logic expressions' do
    expect {
      Dentaku!('true AND')
    }.to raise_error(Dentaku::ParseError)
  end

  it 'evaluates with class-level shortcut functions' do
    expect(Dentaku.evaluate('2+2')).to eq(4)
    expect(Dentaku.evaluate!('2+2')).to eq(4)
    expect { Dentaku.evaluate!('a+1') }.to raise_error(Dentaku::UnboundVariableError)
  end

  it 'evaluates with class-level aliases' do
    Dentaku.aliases = { roundup: ['roundupup'] }
    expect(Dentaku.evaluate('roundupup(6.1)')).to eq(7)
  end
end
