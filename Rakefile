require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

desc "Run specs"
task :spec do
  RSpec::Core::RakeTask.new(:spec) do |t|
    t.rspec_opts = %w{--colour --format progress}
    t.pattern = 'spec/**/*_spec.rb'
  end
end

desc "Default: run specs."
task default: :spec

task :console do
  begin
    require 'pry'
    console = Pry
  rescue LoadError
    require 'irb'
    require 'irb/completion'
    console = IRB
  end

  require 'dentaku'
  ARGV.clear
  console.start
end
