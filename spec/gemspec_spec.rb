require 'spec_helper'

describe 'dentaku.gemspec' do
  # tsort no longer ships as a default gem in Ruby 4.1 (PR #334)
  it 'declares tsort as a runtime dependency' do
    gemspec = Gem::Specification.load(File.expand_path('../dentaku.gemspec', __dir__))
    runtime_deps = gemspec.dependencies.select { |d| d.type == :runtime }.map(&:name)
    expect(runtime_deps).to include('tsort')
  end
end
