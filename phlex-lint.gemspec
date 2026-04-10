# frozen_string_literal: true

require_relative "lib/phlex_lint/version"

Gem::Specification.new do |spec|
  spec.name = "phlex-lint"
  spec.version = PhlexLint::VERSION
  spec.authors = ["Enterprise Modules"]
  spec.email = ["info@enterprisemodules.com"]

  spec.summary = "Semantic linter for Phlex component files"
  spec.description = "Parses Phlex component files into a virtual component tree and enforces " \
                     "design system composition rules — including private helper expansion."
  spec.homepage = "https://github.com/enterprisemodules/phlex-lint"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.files = Dir.chdir(__dir__) do
    Dir["{lib,bin}/**/*", "README.md", "phlex-lint.gemspec"]
  end
  spec.require_paths = ["lib"]
  spec.executables = ["phlex-lint"]

  spec.add_dependency "parser", "~> 3.0"

  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.12"
end
