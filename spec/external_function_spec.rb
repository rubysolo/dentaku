require 'spec_helper'
require 'dentaku'
require 'dentaku/calculator'

describe Dentaku::Calculator do
  describe 'functions' do
    describe 'external functions' do
      let(:custom_calculator) do
        c = described_class.new

        c.add_function(:now, :string, -> { Time.now.to_s })

        fns = [
          [:pow,      :numeric, ->(mantissa, exponent) { mantissa**exponent }],
          [:biggest,  :numeric, ->(*args) { args.max }],
          [:smallest, :numeric, ->(*args) { args.min }],
          [:optional, :numeric, ->(x, y, z = 0) { x + y + z }],
        ]

        c.add_functions(fns)
      end

      it 'includes NOW' do
        now = custom_calculator.evaluate('NOW()')
        expect(now).not_to be_nil
        expect(now).not_to be_empty
      end

      it 'includes POW' do
        expect(custom_calculator.evaluate('POW(2,3)')).to eq(8)
        expect(custom_calculator.evaluate('POW(3,2)')).to eq(9)
        expect(custom_calculator.evaluate('POW(mantissa,exponent)', mantissa: 2, exponent: 4)).to eq(16)
      end

      it 'includes BIGGEST' do
        expect(custom_calculator.evaluate('BIGGEST(8,6,7,5,3,0,9)')).to eq(9)
      end

      it 'includes SMALLEST' do
        expect(custom_calculator.evaluate('SMALLEST(8,6,7,5,3,0,9)')).to eq(0)
      end

      it 'includes OPTIONAL' do
        expect(custom_calculator.evaluate('OPTIONAL(1,2)')).to eq(3)
        expect(custom_calculator.evaluate('OPTIONAL(1,2,3)')).to eq(6)
        expect { custom_calculator.dependencies('OPTIONAL()') }.to raise_error(Dentaku::ParseError)
        expect { custom_calculator.dependencies('OPTIONAL(1,2,3,4)') }.to raise_error(Dentaku::ParseError)
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

    describe 'with callbacks' do
      let(:custom_calculator) do
        c = described_class.new

        @counts = Hash.new(0)

        @initial_time = "2023-02-03"
        @last_time = @initial_time

        c.add_function(
            :reverse,
            :stringl,
            ->(a) { a.reverse },
            lambda do |args|
              args.each do |arg|
                @counts[arg.value] += 1 if arg.type == :string
              end
            end
        )

        fns = [
          [:biggest_callback,  :numeric, ->(*args) { args.max }, ->(args) { args.each { |arg| raise Dentaku::ArgumentError unless arg.type == :numeric } }],
          [:pythagoras, :numeric, ->(l1, l2) { Math.sqrt(l1**2 + l2**2) }, ->(e) { @last_time = Time.now.to_s }],
          [:callback_lambda, :string, ->() { " " }, ->() { "lambda executed" }],
          [:no_lambda_function, :numeric, ->(a) { a**a }],
        ]

        c.add_functions(fns)
      end

      it 'includes BIGGEST_CALLBACK' do
        expect(custom_calculator.evaluate('BIGGEST_CALLBACK(1, 2, 5, 4)')).to eq(5)
        expect { custom_calculator.dependencies('BIGGEST_CALLBACK(1, 3, 6, "hi", 10)') }.to raise_error(Dentaku::ArgumentError)
      end

      it 'includes REVERSE' do
        expect(custom_calculator.evaluate('REVERSE(\'Dentaku\')')).to eq('ukatneD')
        expect { custom_calculator.evaluate('REVERSE(22)') }.to raise_error(NoMethodError)
        expect(@counts["Dentaku"]).to eq(1)
      end

      it 'includes PYTHAGORAS' do
        expect(custom_calculator.evaluate('PYTHAGORAS(8, 7)')).to eq(10.63014581273465)
        expect(custom_calculator.evaluate('PYTHAGORAS(3, 4)')).to eq(5)
        expect(@last_time).not_to eq(@initial_time)
      end

      it 'exposes the `callback` method of a function' do
        expect(Dentaku::AST::Function::Callback_lambda.callback.call()).to eq("lambda executed")
      end

      it 'does not add a `callback` method to built-in functions' do
        expect { Dentaku::AST::If.callback.call }.to raise_error(NoMethodError)
      end

      it 'defaults `callback` method to nil if not specified' do
        expect(Dentaku::AST::Function::No_lambda_function.callback).to eq(nil)
      end
    end

    it 'allows registering "bang" functions' do
      calculator = described_class.new
      calculator.add_function(:hey!, :string, -> { "hey!" })
      expect(calculator.evaluate("hey!()")).to eq("hey!")
    end

    it 'defines for a given function a properly named class that represents it to support AST marshaling' do
      calculator = described_class.new
      expect {
        calculator.add_function(:ho, :string, -> {})
      }.to change {
        Dentaku::AST::Function.const_defined?("Ho")
      }.from(false).to(true)

      expect {
        Marshal.dump(calculator.ast('MAX(1, 2)'))
      }.not_to raise_error
    end

    it 'does not store functions across all calculators' do
      calculator1 = described_class.new
      calculator1.add_function(:my_function, :numeric, ->(x) { 2 * x + 1 })

      calculator2 = described_class.new
      calculator2.add_function(:my_function, :numeric, ->(x) { 4 * x + 3 })

      expect(calculator1.evaluate!("1 + my_function(2)")). to eq(1 + 2 * 2 + 1)
      expect(calculator2.evaluate!("1 + my_function(2)")). to eq(1 + 4 * 2 + 3)

      expect {
        described_class.new.evaluate!("1 + my_function(2)")
      }.to raise_error(Dentaku::ParseError)
    end

    describe 'Dentaku::Calculator.add_function' do
      it 'adds a function to default/global function registry' do
        described_class.add_function(:global_function, :numeric, ->(x) { 10 + x**2 })
        expect(described_class.new.evaluate("global_function(3) + 5")).to eq(10 + 3**2 + 5)
      end
    end

    describe 'Dentaku::Calculator.add_functions' do
      it 'adds multiple functions to default/global function registry' do
        described_class.add_functions([
          [:cube, :numeric, ->(x) { x**3 }],
          [:spongebob, :string, ->(x) { x.split("").each_with_index().map { |c,i| i.even? ? c.upcase : c.downcase }.join() }],
        ])

        expect(described_class.new.evaluate("1 + cube(3)")).to eq(28)
        expect(described_class.new.evaluate("spongebob('How are you today?')")).to eq("HoW ArE YoU ToDaY?")
      end
    end
  end
end
