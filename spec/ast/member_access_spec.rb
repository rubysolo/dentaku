require 'spec_helper'
require 'dentaku'

describe Dentaku::AST::MemberAccess do
  let(:calculator) { Dentaku::Calculator.new }
  let(:users) do
    [
      { age: 20, name: 'Ann', account: { year: 2019 } },
      { :age => 21, 'Name' => 'Bob', :account => { year: 2022 } }
    ]
  end

  def evaluate!(formula, data = { users: users })
    calculator.evaluate!(formula, data)
  end

  it 'reads an attribute of an indexed value' do
    expect(evaluate!('users[0].name')).to eq('Ann')
  end

  it 'reads an attribute of a function result' do
    expect(evaluate!('FILTER(users, u, u.age > 20)[0].age')).to eq(21)
  end

  it 'reads an attribute of a parenthesized expression' do
    expect(evaluate!('(users[0]).age')).to eq(20)
  end

  it 'chains attributes' do
    expect(evaluate!('users[1].account.year')).to eq(2022)
  end

  it 'binds tighter than operators' do
    expect(evaluate!('-users[0].age + 2 * users[1].age')).to eq(22)
    expect(evaluate!('users[1].account.year > users[0].account.year')).to eq(true)
  end

  it 'can be used inside an index' do
    expect(evaluate!('users[users[0].age - 19].account.year')).to eq(2022)
  end

  it 'can be used as a function argument' do
    expect(evaluate!('MAX(users[0].age, users[1].age)')).to eq(21)
  end

  it 'leaves dotted identifiers alone' do
    expect(evaluate!('user.age + 1', user: { age: 30 })).to eq(31)
  end

  describe 'key matching' do
    let(:data) { { h: [{ 'a' => 1, :A => 2, 'Mixed' => 3 }] } }

    it 'accepts string and symbol keys' do
      expect(evaluate!('users[0].age')).to eq(20)
      expect(evaluate!('h[0].a', data)).to eq(1)
    end

    it 'prefers an exact match and otherwise ignores case' do
      expect(evaluate!('h[0].A', data)).to eq(2)
      expect(evaluate!('h[0].mixed', data)).to eq(3)
    end

    it 'matches case exactly in case-sensitive mode' do
      calculator = Dentaku::Calculator.new(case_sensitive: true)
      expect(calculator.evaluate!('h[0].A', data)).to eq(2)
      expect { calculator.evaluate!('h[0].mixed', data) }.to raise_error(Dentaku::ArgumentError)
    end
  end

  describe 'errors' do
    it 'raises for a missing key' do
      expect { evaluate!('users[0].agee') }.to raise_error(Dentaku::ArgumentError, /no key 'agee'/)
    end

    it 'points to brackets for keys that do not look like identifiers' do
      data = { users: [{ 'a.b' => 1 }] }
      expect { evaluate!('users[0].a.b', data) }.to raise_error(Dentaku::ArgumentError, /use brackets for 'a.b'/)
      expect(evaluate!('users[0]["a.b"]', data)).to eq(1)
    end

    it 'raises when the operand is not a hash' do
      expect { evaluate!('users[0].age.x') }.to raise_error(Dentaku::ArgumentError, /requires a hash, but got Integer/)
    end

    it 'is nil-safe' do
      expect(evaluate!('FILTER(users, u, u.age > 99)[0].age')).to be_nil
      expect(evaluate!('FILTER(users, u, u.age > 99)[0].account.year')).to be_nil
      expect(evaluate!('(x).age', x: nil)).to be_nil
    end

    it 'raises for literal operands' do
      expect { evaluate!('("abc").x') }.to raise_error(Dentaku::ArgumentError, /but got String/)
      expect { evaluate!('(1).x') }.to raise_error(Dentaku::ArgumentError, /but got Integer/)
    end

    it 'does not allow whitespace before the dot' do
      expect { evaluate!('users[0] .name') }.to raise_error(Dentaku::TokenizerError)
      expect { evaluate!('(users[0]) .name') }.to raise_error(Dentaku::TokenizerError)
    end

    it 'does not apply after CASE ... END' do
      expect { calculator.ast('CASE 1 WHEN 1 THEN a END.x') }.to raise_error(Dentaku::ParseError)
    end

    it 'does not apply to array literals' do
      expect { calculator.ast('{1, 2}.a') }.to raise_error(Dentaku::ParseError)
    end
  end

  it 'reports dependencies of the structure' do
    expect(calculator.dependencies('users[0].age + x', users: users)).to eq(['x'])
    expect(calculator.identifiers('FILTER(users, u, u.age > x)[0].age')).to eq(%w[users x])
  end

  it 'is an Access' do
    node = calculator.ast('users[0].age')
    expect(node).to be_a(Dentaku::AST::Access)
    expect(node.member).to eq('age')
  end

  it 'has no static type' do
    expect(calculator.ast('users[0].age').type).to be_nil
  end
end
