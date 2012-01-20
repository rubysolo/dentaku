require 'dentaku'

describe Dentaku do
  it 'should evaulate an expression' do
    Dentaku['5+3'].should eql(8)
  end

  it 'should bind values to variables' do
    Dentaku['oranges > 7', {:oranges => 10}].should be_true
  end
end
