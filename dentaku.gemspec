require_relative "lib/dentaku/version"

Gem::Specification.new do |s|
  s.name        = "dentaku"
  s.version     = Dentaku::VERSION
  s.authors     = ["Solomon White"]
  s.email       = ["rubysolo@gmail.com"]
  s.homepage    = "https://github.com/rubysolo/dentaku"
  s.licenses    = %w(MIT)
  s.summary     = 'A formula language parser and evaluator'
  s.description = <<-DESC
    Dentaku is a parser and evaluator for mathematical formulas
  DESC

  s.add_dependency('bigdecimal')
  s.add_dependency('concurrent-ruby')
  s.add_dependency('tsort')

  s.required_ruby_version = ">= 3.2"

  s.files         = `git ls-files`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  s.require_paths = ["lib"]
end
