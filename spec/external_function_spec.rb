require 'spec_helper'
require 'dentaku/calculator'

describe Dentaku::Calculator do
  describe 'functions' do
    describe 'external functions' do

      let(:with_external_funcs) do
        c = described_class.new

        c.add_function(:now, :string, -> { Time.now.to_s })

        fns = [
          [:pow,      :numeric, ->(mantissa, exponent) { mantissa**exponent }],
          [:biggest,  :numeric, ->(*args) { args.max }],
          [:smallest, :numeric, ->(*args) { args.min }],
        ]

        c.add_functions(fns)
      end

      it 'includes NOW' do
        now = with_external_funcs.evaluate('NOW()')
        expect(now).not_to be_nil
        expect(now).not_to be_empty
      end

      it 'includes POW' do
        expect(with_external_funcs.evaluate('POW(2,3)')).to eq(8)
        expect(with_external_funcs.evaluate('POW(3,2)')).to eq(9)
        expect(with_external_funcs.evaluate('POW(mantissa,exponent)', mantissa: 2, exponent: 4)).to eq(16)
      end

      it 'includes BIGGEST' do
        expect(with_external_funcs.evaluate('BIGGEST(8,6,7,5,3,0,9)')).to eq(9)
      end

      it 'includes SMALLEST' do
        expect(with_external_funcs.evaluate('SMALLEST(8,6,7,5,3,0,9)')).to eq(0)
      end

      it 'supports array parameters' do
        calculator = described_class.new
        calculator.add_function(
          :includes,
          :logical,
          ->(haystack, needle) {
            haystack.include?(needle)
          }
        )

        expect(calculator.evaluate("INCLUDES(list, 2)", list: [1, 2, 3])).to eq(true)
      end
    end

    it 'allows registering "bang" functions' do
      calculator = described_class.new
      calculator.add_function(:hey!, :string, -> { "hey!" })
      expect(calculator.evaluate("hey!()")).to eq("hey!")
    end

    it 'defines for a given function a properly named class that represents it' do
      calculator = described_class.new
      calculator.add_function(:ho, :string, -> {})
      expect(Dentaku::AST.const_defined?("Ho")).to eq(true)
    end

    it 'does not define class if it already exists for a given function' do
      calculator = described_class.new
      expect(Dentaku::AST.const_defined?("And")).to eq(true)
      expect {
        calculator.add_function(:and, :logical, -> {})
      }.not_to change { Dentaku::AST::And.object_id }
    end

    it 'does not store functions across all calculators' do
      calculator1 = Dentaku::Calculator.new
      calculator1.add_function(:my_function, :numeric, ->(x) { 2 * x + 1 })

      calculator2 = Dentaku::Calculator.new
      calculator2.add_function(:my_function, :numeric, ->(x) { 4 * x + 3 })

      expect(calculator1.evaluate("1 + my_function(2)")). to eq(1 + 2 * 2 + 1)
      expect(calculator2.evaluate("1 + my_function(2)")). to eq(1 + 4 * 2 + 3)

      expect {
        Dentaku::Calculator.new.evaluate!("1 + my_function(2)")
      }.to raise_error(Dentaku::ParseError)
    end

    it 'self.add_function adds to default/global function registry' do
      Dentaku::Calculator.add_function(:global_function, :numeric, ->(x) { 10 + x**2 })
      expect(Dentaku::Calculator.new.evaluate("global_function(3) + 5")).to eq(10 + 3**2 + 5)
    end
  end
end
