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
end
