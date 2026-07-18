source "http://rubygems.org"

# Specify your gem's dependencies in dentaku.gemspec
gemspec

group :development, :test do
  gem 'pry'
  gem 'pry-byebug'
  gem 'pry-stack_explorer'
  gem 'rake'
  gem 'rspec'
  gem 'rubocop'
  # Stay on the 0.x line: simplecov 1.0 (2026-07) removed SimpleCov.running,
  # which the RubyMine/IntelliJ coverage runner still relies on. Lift this
  # once the IDE integration supports 1.0.
  gem 'simplecov', '< 1.0'
end
