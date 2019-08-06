lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'puppetdb/version'

Gem::Specification.new do |s|
  s.name          = 'puppetdb-ruby'
  s.version       = PuppetDB::VERSION
  s.summary       = 'Simple Ruby client library for PuppetDB API'
  s.authors       = ['Vox Pupuli', 'Nathaniel Smith', 'Lindsey Smith']
  s.email         = 'voxpupuli@groups.io'
  s.files         = Dir['CHANGELOG.md', 'README.md', 'LICENSE', 'lib/**/*']
  s.homepage      = 'https://github.com/voxpupuli/puppetdb-ruby'
  s.license       = 'Apache-2.0'
  s.require_paths = ['lib']
  s.add_runtime_dependency 'httparty'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'mocha'
  s.add_development_dependency 'rubocop', '0.48.1'
  s.add_development_dependency 'rubocop-rspec', '1.15.1'
  s.add_development_dependency 'github_changelog_generator'
end
