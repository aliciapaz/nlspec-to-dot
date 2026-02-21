# frozen_string_literal: true

require_relative "lib/nlspec_to_dot/version"

Gem::Specification.new do |spec|
  spec.name = "nlspec-to-dot"
  spec.version = NlspecToDot::VERSION
  spec.authors = ["Telos"]
  spec.summary = "Compile natural language specs into DOT pipelines for attractor"
  spec.description = "Parses structured markdown NLSpecs describing Rails apps and emits DOT pipeline files executable by the attractor engine."
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.3.0"

  spec.files = Dir["lib/**/*", "bin/*", "LICENSE", "README.md"]
  spec.bindir = "bin"
  spec.executables = ["nlspec-to-dot"]

  spec.add_dependency "thor", "~> 1.3"

  spec.metadata["rubygems_mfa_required"] = "true"
end
