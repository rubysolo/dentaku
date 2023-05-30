require 'spec_helper'
require 'dentaku/ast/functions/intercept'
require 'dentaku'

describe 'Dentaku::AST::Function::Intercept' do
  it 'returns the correct intercept for given x and y arrays' do
    x_values = [1, 2, 3, 4, 5]
    y_values = [2, 3, 5, 4, 6]
    result = Dentaku('INTERCEPT(?, ?)', x_values, y_values)
    expect(result).to be_within(0.001).of(1.2)
  end

  context 'checking errors' do
    it 'raises an error if arguments are not arrays' do
      expect { Dentaku!("INTERCEPT(1, 2)") }.to raise_error(Dentaku::ArgumentError)
    end

    it 'raises an error if the arrays are not of equal length' do
      x_values = [1, 2, 3]
      y_values = [2, 3, 5, 4]
      expect { Dentaku!("INTERCEPT(?, ?)", x_values, y_values) }.to raise_error(Dentaku::ArgumentError)
    end

    it 'raises an error if any of the arrays is empty' do
      x_values = []
      y_values = [2, 3, 5, 4]
      expect { Dentaku!("INTERCEPT(?, ?)", x_values, y_values) }.to raise_error(Dentaku::ArgumentError)
    end
  end
end
