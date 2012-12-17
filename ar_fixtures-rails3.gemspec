# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ar_fixtures-rails3/version'

Gem::Specification.new do |gem|
  gem.name          = "ar_fixtures-rails3"
  gem.version       = ArFixtures::Rails3::VERSION
  gem.authors       = ["Faraaz Khan"]
  gem.email         = ["faraaz@rationalizeit.us"]
  gem.description   = %q{This is a port of the ar_fixtures plugin to Rails 3}
  gem.summary       = %q{Creates text fixtures from data in the database}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
end
