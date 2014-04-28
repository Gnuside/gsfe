# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'gsfe/version'

Gem::Specification.new do |spec|
  spec.name          = "gsfe"
  spec.version       = Gsfe::VERSION
  spec.authors       = ["Glenn Y. Rolland"]
  spec.email         = ["glenn.rolland@gnuside.com"]
  spec.summary       = %q{A converter for GIMP slices.}
  spec.description   = %q{A converter for GIMP slices.}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "nokogiri"
  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
end
