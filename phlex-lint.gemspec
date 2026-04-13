# frozen_string_literal: true

require_relative "lib/phlex_lint/version"

Gem::Specification.new do |spec|
  spec.name = "phlex-lint"
  spec.version = PhlexLint::VERSION
  spec.authors = ["Enterprise Modules"]
  spec.email = ["info@enterprisemodules.com"]

  spec.summary = "Semantic linter for Phlex component composition"
  spec.description = "Validates Phlex component composition rules against the virtual component tree"
  spec.homepage = "https://github.com/prospects-radar/phlex-lint"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.files = Dir["lib/**/*.rb", "bin/*"].sort
  spec.bindir = "bin"
  spec.executables = ["phlex-lint"]
  spec.require_paths = ["lib"]
end
