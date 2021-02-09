require_relative "lib/outliertree/version"

Gem::Specification.new do |spec|
  spec.name          = "outliertree"
  spec.version       = OutlierTree::VERSION
  spec.summary       = "Explainable outlier/anomaly detection for Ruby"
  spec.homepage      = "https://github.com/ankane/outliertree"
  spec.license       = "GPL-3.0-or-later"

  spec.author        = "Andrew Kane"
  spec.email         = "andrew@ankane.org"

  spec.files         = Dir["*.{md,txt}", "{ext,lib}/**/*", "vendor/outliertree/{LICENSE,README.md}", "vendor/outliertree/src/**/*"]
  spec.require_path  = "lib"
  spec.extensions    = ["ext/outliertree/extconf.rb"]

  spec.required_ruby_version = ">= 2.5"

  spec.add_dependency "rice", ">= 2.2"
end
