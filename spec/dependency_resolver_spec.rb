require 'spec_helper'
require 'dentaku/dependency_resolver'

describe Dentaku::DependencyResolver do
  it 'sorts expressions in dependency order' do
    dependencies = {"first" => ["second"], "second" => ["third"], "third" => []}
    expect(described_class.find_resolve_order(dependencies)).to eq(
      ["third", "second", "first"]
    )
  end

  it 'handles case differences' do
    dependencies = {"FIRST" => ["second"], "SeCoNd" => ["third"], "THIRD" => []}
    expect(described_class.find_resolve_order(dependencies)).to eq(
      ["THIRD", "SeCoNd", "FIRST"]
    )
  end
end
