require 'spec_helper'

require 'dentaku'

class User
  attr_reader :age, :profile

  def initialize(age, profile)
    @age = age
    @profile = profile
  end
end

class Profile
  attr_reader :favorite_color

  def initialize(favorite_color)
    @favorite_color = favorite_color
  end
end

class LazyResolver
  attr_reader :calculator

  def initialize(calculator)
    @calculator = calculator
  end

  # fake it until you make it
  def unbound_variables(_node)
    []
  end

  def fetch(variable_name)
    variable_name.split(".").reduce(calculator.memory) do |mem, segment|
      case
      when mem.respond_to?(:fetch) then mem.fetch(segment)
      when mem.respond_to?(segment) then mem.send(segment)
      else
        raise "error resolving variable #{variable_name} at segment #{segment}"
      end
    end
  end

  # def update(data)
  # end

  # def []=(variable_name, value)
  # end
end

RSpec.describe "custom variable resolver" do
  it "allows lazy resolution of nested values" do
    user = User.new(21, Profile.new("red"))
    calculator = Dentaku::Calculator.new(nested_data_support: false, variable_resolver: LazyResolver)
    expect(calculator.evaluate!("user.age >= 18 AND user.profile.favorite_color = 'red'", user: user)).to eq(true)
  end
end
