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
  s.summary     = %q{A formula language parser and evaluator}
  s.description = <<-DESC
    Dentaku is a parser and evaluator for mathematical formulas
  DESC

  s.rubyforge_project = "dentaku"

  s.add_development_dependency('rake')
  s.add_development_dependency('rspec')
  s.add_development_dependency('pry')

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
