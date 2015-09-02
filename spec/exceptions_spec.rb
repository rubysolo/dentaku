require 'spec_helper'
require 'dentaku/exceptions'

describe Dentaku::UnboundVariableError do
  it 'includes variable name(s) in message' do
    exception = described_class.new(['length'])
    expect(exception.message).to match /length/
  end
end
