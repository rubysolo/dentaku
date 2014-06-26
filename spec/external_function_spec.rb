require 'dentaku/calculator'

describe Dentaku::Calculator do
  describe 'functions' do
    describe 'external functions' do

      let(:with_external_funcs) do
        c = described_class.new

        now = { name: :now, type: :string, signature: [], body: -> { Time.now.to_s } }
        c.add_function(now)

        fns = [
          {
            name:      :exp,
            type:      :numeric,
            signature: [ :numeric, :numeric ],
            body:      ->(mantissa, exponent) { mantissa ** exponent }
          },
          {
            name:      :max,
            type:      :numeric,
            signature: [ :non_close_plus ],
            body:      ->(*args) { args.max }
          },
          {
            name:      :min,
            type:      :numeric,
            signature: [ :non_close_plus ],
            body:      ->(*args) { args.min }
          }
        ]

        c.add_functions(fns)
      end

      it 'includes NOW' do
        now = with_external_funcs.evaluate('NOW()')
        expect(now).not_to be_nil
        expect(now).not_to be_empty
      end

      it 'includes EXP' do
        expect(with_external_funcs.evaluate('EXP(2,3)')).to eq(8)
        expect(with_external_funcs.evaluate('EXP(3,2)')).to eq(9)
        expect(with_external_funcs.evaluate('EXP(mantissa,exponent)', mantissa: 2, exponent: 4)).to eq(16)
      end

      it 'includes MAX' do
        expect(with_external_funcs.evaluate('MAX(8,6,7,5,3,0,9)')).to eq(9)
      end

      it 'includes MIN' do
        expect(with_external_funcs.evaluate('MIN(8,6,7,5,3,0,9)')).to eq(0)
      end
    end
  end
end
