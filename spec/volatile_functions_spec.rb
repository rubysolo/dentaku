require 'spec_helper'
require 'dentaku'
require 'dentaku/calculator'

describe Dentaku::Calculator do
  describe 'volatile functions' do
    let(:calculator) { described_class.new }
    let(:call_count) { { count: 0 } }

    def register_counter(volatile:)
      counter = call_count
      calculator.add_function(:vol, :numeric, ->(x) { counter[:count] += 1; x }, volatile: volatile)
    end

    describe 'registration' do
      it 'marks generated function classes volatile' do
        registry = Dentaku::AST::FunctionRegistry.new
        registry.register(:vol, :numeric, ->(x) { x }, volatile: true)
        expect(registry.get(:vol).volatile?).to be true
      end

      it 'defaults to non-volatile' do
        registry = Dentaku::AST::FunctionRegistry.new
        registry.register(:plain, :numeric, ->(x) { x })
        expect(registry.get(:plain).volatile?).to be_falsy
      end

      it 'reports built-in function classes as non-volatile' do
        expect(Dentaku::AST::If.volatile?).to be false
      end

      it 'accepts a fifth tuple element in add_functions' do
        calculator.add_functions([
          [:vol5, :numeric, ->(x) { x }, nil, true],
          [:plain5, :numeric, ->(x) { x }],
        ])
        expect(calculator.dependencies('IF(vol5(1) > 0, a, b)')).to eq(%w(a b))
        expect(calculator.dependencies('IF(plain5(1) > 0, a, b)')).to eq(['a'])
      end
    end

    describe 'dependency resolution' do
      it 'does not evaluate a volatile IF predicate and returns both branches' do
        register_counter(volatile: true)
        expect(calculator.dependencies('IF(vol(1) > 0, a, b)')).to eq(%w(a b))
        expect(call_count[:count]).to eq(0)
      end

      it 'still prunes when the predicate uses a pure custom function' do
        register_counter(volatile: false)
        expect(calculator.dependencies('IF(vol(1) > 0, a, b)')).to eq(['a'])
        expect(call_count[:count]).to eq(1)
      end

      it 'treats volatility as recursive through the guard subtree' do
        register_counter(volatile: true)
        expect(calculator.dependencies('IF(1 + vol(1) > 2, a, b)')).to eq(%w(a b))
        expect(call_count[:count]).to eq(0)
      end

      it 'does not prune CASE with a volatile switch' do
        register_counter(volatile: true)
        deps = calculator.dependencies('CASE vol(1) WHEN 1 THEN a ELSE b END')
        expect(deps).to eq(%w(a b))
        expect(call_count[:count]).to eq(0)
      end

      it 'does not prune CASE with a volatile when-clause' do
        register_counter(volatile: true)
        deps = calculator.dependencies('CASE 1 WHEN vol(1) THEN a ELSE b END')
        expect(deps).to eq(%w(a b))
        expect(call_count[:count]).to eq(0)
      end

      it 'does not treat a volatile AND operand as decisive' do
        register_counter(volatile: true)
        expect(calculator.dependencies('vol(0) > 1 AND x')).to eq(['x'])
        expect(call_count[:count]).to eq(0)
      end

      it 'still prunes AND on a pure decisive operand without running the volatile side' do
        register_counter(volatile: true)
        expect(calculator.dependencies('1 > 2 AND vol(1) > 0')).to eq([])
        expect(call_count[:count]).to eq(0)
      end
    end

    describe 'evaluation' do
      it 'evaluates a volatile predicate exactly once per evaluate!' do
        register_counter(volatile: true)
        expect(calculator.evaluate!('IF(vol(2) > 1, a, b)', a: 1, b: 2)).to eq(1)
        expect(call_count[:count]).to eq(1)
      end

      it 'requires variables from both branches when the predicate is volatile' do
        register_counter(volatile: true)
        expect {
          calculator.evaluate!('IF(vol(2) > 1, a, b)', a: 1)
        }.to raise_error(Dentaku::UnboundVariableError) { |error|
          expect(error.unbound_variables).to eq(['b'])
        }
      end

      it 'does not change runtime short-circuit behavior for direct AST evaluation' do
        register_counter(volatile: true)
        node = calculator.ast('IF(vol(2) > 1, a, b)')
        expect(node.value('a' => 1)).to eq(1)
        expect(call_count[:count]).to eq(1)
      end
    end

    describe 'solve' do
      it 'resolves expressions with volatile guards when all branch inputs are provided' do
        register_counter(volatile: true)
        calculator.store(a: 1, b: 2)
        result = calculator.solve!(c: 'IF(vol(2) > 1, a, b)', d: 'c + 1')
        expect(result[:d]).to eq(2)
      end
    end
  end
end
