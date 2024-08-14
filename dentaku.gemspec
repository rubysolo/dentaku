# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "dentaku/version"

Gem::Specification.new do |s|
  s.name        = "dentaku"
  s.version     = Dentaku::VERSION
  s.authors     = ["Solomon White"]
  s.email       = ["rubysolo@gmail.com"]
  s.homepage    = "http://github.com/rubysolo/dentaku"
  s.licenses    = %w(MIT)
  s.summary     = 'A formula language parser and evaluator'
  s.description = <<-DESC
    Dentaku is a parser and evaluator for mathematical formulas
  DESC

  s.add_dependency('bigdecimal')
  s.add_dependency('concurrent-ruby')

  s.add_development_dependency('codecov')
  s.add_development_dependency('pry')
  s.add_development_dependency('pry-byebug')
  s.add_development_dependency('pry-stack_explorer')
  s.add_development_dependency('rake')
  s.add_development_dependency('rspec')
  s.add_development_dependency('rubocop')
  s.add_development_dependency('simplecov')

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  s.require_paths = ["lib"]
end
