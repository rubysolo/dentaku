require 'spec_helper'
require 'dentaku/ast/function'

class Clazz; end

describe Dentaku::AST::Function do
  let(:calculator) { Dentaku::Calculator.new }

  it 'maintains a function registry' do
    expect(described_class).to respond_to(:get)
  end

  it 'raises an exception when trying to access an undefined function' do
    expect {
      described_class.get("flarble")
    }.to raise_error(Dentaku::ParseError, /undefined function/i)
  end

  it 'registers a custom function' do
    calculator.add_function("flarble", :string, -> { "flarble" })
    function = calculator.function_registry.get("flarble").new
    expect(function.value).to eq "flarble"
  end

  it 'does not throw an error when registering a function with a name that matches a currently defined constant' do
    expect { calculator.add_function("clazz", :string, -> { "clazzified" }) }.not_to raise_error
  end

  describe "#name" do
    it "for custom functions, gives a string representation of the function" do
      calculator.add_function("alpha", :numeric, ->() { 10 })
      function = calculator.function_registry.get("alpha").new
      expect(function.name).to eq :alpha
    end
  end

  describe "#arity" do
    it "gives the correct arity for custom functions" do
      calculator.add_function("alpha", :numeric, ->() { 10 })
      function = calculator.function_registry.get("alpha").new
      expect(function.arity).to eq 0

      calculator.add_function("beta", :numeric, ->(x) { 2*x })
      function = calculator.function_registry.get("beta").new
      expect(function.arity).to eq 1

      calculator.add_function("gamma", :numeric, ->(x,y) { x + y })
      function = calculator.function_registry.get("gamma").new
      expect(function.arity).to eq 2

      calculator.add_function("delta", :numeric, ->(*args) { args.max })
      function = calculator.function_registry.get("delta").new
      expect(function.arity).to eq nil
    end
  end
end
