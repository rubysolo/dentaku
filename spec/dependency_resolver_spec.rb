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

  it 'sorts mixed-case expressions in dependency order when case-sensitive' do
    dependencies = {"TopLevel" => ["MidLevel"], "MidLevel" => ["BottomLevel"], "BottomLevel" => []}
    expect(described_class.find_resolve_order(dependencies, true)).to eq(
      ["BottomLevel", "MidLevel", "TopLevel"]
    )
  end

  it 'treats variables that differ only in case as distinct when case-sensitive' do
    dependencies = {"foo" => ["FOO"], "FOO" => []}
    expect(described_class.find_resolve_order(dependencies, true)).to eq(
      ["FOO", "foo"]
    )
  end
end
