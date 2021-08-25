require 'bigdecimal'
require 'spec_helper'
require 'dentaku/ast/function'
require 'dentaku/exceptions'

class Clazz; end

describe Dentaku::AST::Function do
  it 'maintains a function registry' do
    expect(described_class).to respond_to(:get)
  end

  it 'registers a custom function' do
    described_class.register("flarble", :string, -> { "flarble" })
    expect { described_class.get("flarble") }.not_to raise_error
    function = described_class.get("flarble").new
    expect(function.value).to eq("flarble")
  end

  it 'does not throw an error when registering a function with a name that matches a currently defined constant' do
    expect { described_class.register("clazz", :string, -> { "clazzified" }) }.not_to raise_error
  end

  describe "#arity" do
    it "returns the correct arity for custom functions" do
      zero = described_class.register("zero", :numeric, ->() { 0 })
      expect(zero.arity).to eq(0)

      one = described_class.register("one", :numeric, ->(x) { x * 2 })
      expect(one.arity).to eq(1)

      two = described_class.register("two", :numeric, ->(x, y) { x + y })
      expect(two.arity).to eq(2)

      many = described_class.register("many", :numeric, ->(*args) { args.max })
      expect(many.arity).to be_nil
    end
  end

  it 'casts a String to an Integer if possible' do
    expect(described_class.numeric('3')).to eq(3)
  end

  it 'casts a String to a BigDecimal if possible and if Integer would loose information' do
    expect(described_class.numeric('3.2')).to eq(3.2)
  end

  it 'casts a String to a BigDecimal with a negative number' do
    expect(described_class.numeric('-3.2')).to eq(-3.2)
  end

  it 'casts a String to a BigDecimal without a leading zero' do
    expect(described_class.numeric('-.2')).to eq(-0.2)
  end

  it 'raises an error if the value could not be cast to a Numeric' do
    expect { described_class.numeric('flarble') }.to raise_error Dentaku::ArgumentError
    expect { described_class.numeric('-') }.to raise_error Dentaku::ArgumentError
    expect { described_class.numeric('') }.to raise_error Dentaku::ArgumentError
    expect { described_class.numeric(nil) }.to raise_error Dentaku::ArgumentError
    expect { described_class.numeric('7.') }.to raise_error Dentaku::ArgumentError
    expect { described_class.numeric(true) }.to raise_error Dentaku::ArgumentError
  end

  it "allows read access to arguments" do
    fn = described_class.new(1, 2, 3)
    expect(fn.args).to eq([1, 2, 3])
  end
end
