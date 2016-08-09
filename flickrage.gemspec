# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'flickrage/version'

Gem::Specification.new do |spec|
  spec.name          = 'flickrage'
  spec.version       = Flickrage::VERSION
  spec.authors       = ['Alexander Merkulov']
  spec.email         = ['sasha@merqlove.ru']

  spec.summary       = %q{Another one Flickr collage maker CLI.}
  spec.description   = %q{Another one Flickr collage maker CLI.}
  spec.homepage      = 'https://github.com/merqlove/flickrage'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|assets|spec|features)/}) }
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']
  spec.licenses      = ['MIT']

  spec.required_ruby_version = '>= 2.3.0'

  spec.add_dependency 'thor', '~> 0.19'
  spec.add_dependency 'flickraw', '~> 0.9.9'
  spec.add_dependency 'mini_magick', '~> 4.5.1'
  spec.add_dependency 'dry-configurable', '~> 0.1.7'
  spec.add_dependency 'dry-types', '~> 0.8.1'
  spec.add_dependency 'concurrent-ruby-edge'
  spec.add_dependency 'tty-spinner', '~> 0.3.0'
  spec.add_dependency 'pastel', '~> 0.6.0'

  spec.add_development_dependency 'bundler', '~> 1.12'
  spec.add_development_dependency 'rake', '~> 10.0'

  spec.add_development_dependency 'json', '~> 1.8.1'
  spec.add_development_dependency 'rspec', '~> 3.5.0'
  spec.add_development_dependency 'rspec-core', '~> 3.5.0'
  spec.add_development_dependency 'rspec-expectations', '~> 3.5.0'
  spec.add_development_dependency 'rspec-mocks', '~> 3.5.0'
  spec.add_development_dependency 'webmock', '~> 2.1.0'
  spec.add_development_dependency 'coveralls', '~> 0.8.15'
end
