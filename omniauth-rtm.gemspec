# -*- encoding: utf-8 -*-
require File.expand_path('../lib/omniauth-rtm/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Nickolay Abdrafikov"]
  gem.email         = ["nicck.olay@gmail.com"]
  gem.description   = %q{OmniAuth strategy for Remember The Milk}
  gem.summary       = %q{OmniAuth strategy for Remember The Milk}
  gem.homepage      = "http://github.com/nicck/omniauth-rtm"

  gem.add_runtime_dependency     'omniauth', '~> 1.0'
  gem.add_runtime_dependency     'moocow', '~> 1.1.0'

  gem.add_development_dependency 'rspec', '~> 2.6'
  gem.add_development_dependency 'simplecov'
  gem.add_development_dependency 'rack-test'

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "omniauth-rtm"
  gem.require_paths = ["lib"]
  gem.version       = Omniauth::RTM::VERSION
end
