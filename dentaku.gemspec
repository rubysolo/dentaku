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

  s.metadata = {
    "homepage_uri"          => s.homepage,
    "source_code_uri"       => s.homepage,
    "changelog_uri"         => "#{s.homepage}/blob/main/CHANGELOG.md",
    "bug_tracker_uri"       => "#{s.homepage}/issues",
    "rubygems_mfa_required" => "true",
  }

  s.add_dependency('bigdecimal', '>= 3.1')
  s.add_dependency('concurrent-ruby', '~> 1.1')
  s.add_dependency('tsort', '>= 0.1.1')

  s.required_ruby_version = ">= 3.2"

  s.files         = `git ls-files`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  s.require_paths = ["lib"]
end
