require 'dentaku/rule_set'

describe Dentaku::RuleSet do
  subject { described_class.new }

  it 'yields core rules' do
    functions = []
    subject.each { |pattern, function| functions << function }
    expect(functions).to eq [:if,
                             :round,
                             :round_int,
                             :round_int,
                             :not,
                             :evaluate_group,
                             :negate,
                             :apply,
                             :pow_negate,
                             :apply,
                             :apply,
                             :mul_negate,
                             :apply,
                             :percentage,
                             :negate,
                             :expand_range,
                             :expand_range,
                             :apply,
                             :apply,
                             :apply,
                            ]
  end

  it 'adds custom function patterns' do
    functions = []
    subject.add_function(
      name:      :min,
      type:      :numeric,
      signature: [ :arguments ],
      body:      ->(*args) { args.min }
    )
    subject.each { |pattern, function| functions << function }
    expect(functions).to include('min')
  end
end
