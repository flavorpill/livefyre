# -*- encoding: utf-8 -*-
require File.expand_path('../lib/livefyre/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Mashable"]
  gem.email         = ["cheald@mashable.com"]
  gem.description   = %q{TODO: Interface library for Livefyre's comment API}
  gem.summary       = %q{TODO: Interface library for Livefyre's comment API}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(spec)/})
  gem.name          = "livefyre"
  gem.require_paths = ["lib"]
  gem.version       = Livefyre::VERSION

  gem.add_dependency "faraday"
  gem.add_dependency "jwt"

  gem.add_development_dependency "rspec"
  gem.add_development_dependency "simplecov"
  gem.add_development_dependency "simplecov-rcov"
end