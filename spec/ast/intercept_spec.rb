require 'spec_helper'
require 'dentaku/ast/functions/intercept'
require 'dentaku'

describe 'Dentaku::AST::Function::Intercept' do
  it 'returns the correct intercept for given x and y arrays' do
    x_values = [6, 13, 15, 10, 11, 10]
    y_values = [-1, 8, 8,  13, 3, 15]
    result = Dentaku('INTERCEPT(ys, xs)', xs: x_values, ys: y_values)
    expect(result).to be_within(0.001).of(9.437)
  end

  context 'checking errors' do
    it 'raises an error if arguments are not arrays' do
      expect { Dentaku!("INTERCEPT(1, 2)") }.to raise_error(Dentaku::ArgumentError)
    end

    it 'raises an error if the arrays are not of equal length' do
      x_values = [1, 2, 3]
      y_values = [2, 3, 5, 4]
      expect { Dentaku!("INTERCEPT(y, x)", x: x_values, y: y_values) }.to raise_error(Dentaku::ArgumentError)
    end

    it 'raises an error if any of the arrays is empty' do
      x_values = []
      y_values = [2, 3, 5, 4]
      expect { Dentaku!("INTERCEPT(y, x)", x: x_values, y: y_values) }.to raise_error(Dentaku::ArgumentError)
    end
  end
end
