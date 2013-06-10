# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'dee_bee/version'

Gem::Specification.new do |spec|
  spec.name          = "dee_bee"
  spec.version       = DeeBee::VERSION
  spec.authors       = ["Jim Cifarelli"]
  spec.email         = ["cifarelli@gmail.com"]
  spec.description   = %q{Ruby based utilities for database backup, file rotation, and syncing to remote storage}
  spec.summary       = %q{Ruby based utilities for database backup, file rotation, and syncing to remote storage}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec", "~> 2.6"
  spec.add_development_dependency "mocha", "~> 0.14.0"
  spec.add_development_dependency "timecop", "~> 0.6"
  spec.add_development_dependency "fakefs", "~> 0.4"

  spec.add_dependency("fog", "~> 1.10.1")
  spec.add_dependency("term-ansicolor")
end
