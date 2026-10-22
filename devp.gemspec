require_relative "lib/devp/version"

Gem::Specification.new do |spec|
  spec.name          = "devp"
  spec.version       = DevP::VERSION
  spec.authors       = ["Ruby Dev Productivity"]
  spec.email         = ["dev@example.com"]

  spec.summary       = "Developer Productivity CLI"
  spec.description   = "Track work sessions, time, daily logs, and export summaries."
  spec.homepage      = "github.com/mefaisalraheem/ruby-dev-productivity-cli"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.files         = Dir["lib/**/*.rb", "bin/*", "README.md"]
  spec.bindir        = "bin"
  spec.executables   = ["devp"]
  spec.require_paths = ["lib"]

  spec.add_development_dependency "rspec", "~> 3.12"
  spec.add_development_dependency "rake", "~> 13.0"
end