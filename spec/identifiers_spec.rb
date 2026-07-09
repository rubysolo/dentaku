require 'spec_helper'
require 'dentaku'
require 'dentaku/calculator'

describe Dentaku::Calculator do
  describe '#identifiers' do
    let(:calculator) { described_class.new }

    it 'does not prune literal guards' do
      expect(calculator.identifiers('IF(1 > 0, a, b)')).to eq(%w(a b))
    end

    it 'includes the guard identifiers themselves' do
      expect(calculator.identifiers('IF(x > 5, y, z)')).to eq(%w(x y z))
    end

    it 'never executes functions, pure or volatile' do
      count = { pure: 0, volatile: 0 }
      calculator.add_function(:purefn, :numeric, ->(x) { count[:pure] += 1; x })
      calculator.add_function(:volfn, :numeric, ->(x) { count[:volatile] += 1; x }, volatile: true)

      expect(calculator.identifiers('IF(purefn(1) > 0, a, IF(volfn(2) > 0, b, c))')).to eq(%w(a b c))
      expect(count).to eq(pure: 0, volatile: 0)
    end

    it 'includes switch and every branch of CASE' do
      formula = 'CASE fruit WHEN w1 THEN t1 WHEN 2 THEN t2 ELSE e1 END'
      expect(calculator.identifiers(formula)).to eq(%w(fruit w1 t1 t2 e1))
    end

    it 'includes both operands of AND/OR even when one is decisive' do
      expect(calculator.identifiers('1 > 2 AND x')).to eq(['x'])
      expect(calculator.identifiers('a AND b OR c')).to eq(%w(a b c))
    end

    it 'excludes enum-bound variables' do
      expect(calculator.identifiers('MAP(users, u, u.age + bonus)')).to eq(%w(users bonus))
    end

    it 'ignores stored memory' do
      calculator.store(a: 1)
      expect(calculator.identifiers('a + b')).to eq(%w(a b))
    end

    it 'accepts an AST node' do
      node = calculator.ast('x + y')
      expect(calculator.identifiers(node)).to eq(%w(x y))
    end

    it 'accepts an array of expressions and deduplicates' do
      expect(calculator.identifiers(['a + b', 'b + c'])).to eq(%w(a b c))
    end

    it 'deduplicates repeated identifiers' do
      expect(calculator.identifiers('a + a * a')).to eq(['a'])
    end

    it 'lists all inputs of a formula using external-state functions' do
      user_attr = ->(name, default = 0) { default }
      calculator.add_function(:user_attr, :numeric, user_attr)

      identifiers = calculator.identifiers("IF(user_attr('level') > 50, high_level_value, low_level_value)")
      expect(identifiers).to eq(%w(high_level_value low_level_value))
    end
  end
end
