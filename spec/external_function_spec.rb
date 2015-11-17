require 'spec_helper'
require 'dentaku/calculator'

describe Dentaku::Calculator do
  describe 'functions' do
    describe 'external functions' do

      let(:with_external_funcs) do
        c = described_class.new

        c.add_function(:now, :string, -> { Time.now.to_s })

        fns = [
          [:pow,      :numeric, ->(mantissa, exponent) { mantissa ** exponent }],
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

        expect(calculator.evaluate("INCLUDES(list, 2)", list: [1,2,3])).to eq(true)
      end
    end
  end
end
