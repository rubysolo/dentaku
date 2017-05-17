require 'bigdecimal'
require 'spec_helper'
require 'dentaku/ast/function'
require 'dentaku/exceptions'

class Clazz; end

describe Dentaku::AST::Function do
  it 'maintains a function registry' do
    expect(described_class).to respond_to(:get)
  end

  it 'raises an exception when trying to access an undefined function' do
    expect {
      described_class.get("flarble")
    }.to raise_error(Dentaku::ParseError, /undefined function/i)
  end

  it 'registers a custom function' do
    described_class.register("flarble", :string, -> { "flarble" })
    expect { described_class.get("flarble") }.not_to raise_error
    function = described_class.get("flarble").new
    expect(function.value).to eq "flarble"
  end

  it 'does not throw an error when registering a function with a name that matches a currently defined constant' do
    expect { described_class.register("clazz", :string, -> { "clazzified" }) }.not_to raise_error
  end

  it 'casts a String to an Integer if possible' do
    expect(described_class.numeric('3')).to eq 3
  end

  it 'casts a String to a BigDecimal if possible and if Integer would loose information' do
    expect(described_class.numeric('3.2')).to eq 3.2
  end

  it 'casts a String to a BigDecimal with a negative number' do
    expect(described_class.numeric('-3.2')).to eq -3.2
  end

  it 'casts a String to a BigDecimal without a leading zero' do
    expect(described_class.numeric('-.2')).to eq -0.2
  end

  it 'raises an error if the value could not be cast to a Numeric' do
    expect { described_class.numeric('flarble') }.to raise_error TypeError
    expect { described_class.numeric('-') }.to raise_error TypeError
    expect { described_class.numeric('') }.to raise_error TypeError
    expect { described_class.numeric(nil) }.to raise_error TypeError
    expect { described_class.numeric('-.') }.to raise_error TypeError
  end
end
