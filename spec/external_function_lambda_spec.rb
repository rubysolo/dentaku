require 'spec_helper'
require 'dentaku'
require 'dentaku/calculator'

describe Dentaku::Calculator do
  describe 'functions' do
    describe 'external functions' do

      let(:with_external_funcs) do
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
        expect(with_external_funcs.evaluate('BIGGEST_CALLBACK(1, 2, 5, 4)')).to eq(5)
        expect { with_external_funcs.dependencies('BIGGEST_CALLBACK(1, 3, 6, "hi", 10)') }.to raise_error(Dentaku::ArgumentError)
      end

      it 'includes REVERSE' do
        expect(with_external_funcs.evaluate('REVERSE(\'Dentaku\')')).to eq('ukatneD')
        expect { with_external_funcs.evaluate('REVERSE(22)') }.to raise_error(NoMethodError)
        expect(@counts["Dentaku"]).to eq(1)
      end

      it 'includes PYTHAGORAS' do
        expect(with_external_funcs.evaluate('PYTHAGORAS(8, 7)')).to eq(10.63014581273465)
        expect(with_external_funcs.evaluate('PYTHAGORAS(3, 4)')).to eq(5)
        expect(@last_time).not_to eq(@initial_time)
      end

      it 'call CALLBACK method of function' do
        expect(Dentaku::AST::Function::Callback_lambda.callback.call()).to eq("lambda executed")
      end

      it 'call CALLBACK in no external function' do
        expect { Dentaku::AST::If.callback.call }.to raise_error(NoMethodError)
      end

      it 'set CALLBACK to nil in external function with no callback' do
        expect(Dentaku::AST::Function::No_lambda_function.callback).to eq(nil)
      end
    end
  end
end
