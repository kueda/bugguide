# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'bugguide/version'

Gem::Specification.new do |spec|
  spec.name          = "bugguide"
  spec.version       = BugGuide::VERSION
  spec.authors       = ["Ken-ichi Ueda"]
  spec.email         = ["kenichi.ueda@gmail.com"]

  spec.summary       = "Library to read North American insect data from BugGuide.net."
  spec.description   = %q{
    BugGuide.net is a website for sharing insect photos from North America.
    Over the years it as acrued many experts and a great deal of excellent
    data, but not an API. This gem is little more than a scraper for
    conveniently extracting data from the website.
  }
  spec.homepage      = "https://github.com/kueda/bugguide"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "bin"
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest", "~> 5.8"
  spec.add_development_dependency "m", "~> 1.4"
  spec.add_runtime_dependency 'nokogiri', "~> 1.6"
  spec.add_runtime_dependency 'activesupport', "~> 4.2"
  spec.add_runtime_dependency 'commander', "~> 4.3"
end
