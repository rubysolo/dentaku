require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

desc "Run specs"
task :spec do
  RSpec::Core::RakeTask.new(:spec) do |t|
    t.rspec_opts = %w{--colour --format progress}
    t.pattern = 'spec/*_spec.rb'
  end
end

desc "Default: run specs."
task :default => :spec
