lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'puppetdb/version'

Gem::Specification.new do |s|
  s.name          = 'puppetdb-ruby'
  s.version       = PuppetDB::VERSION
  s.summary       = 'Simple Ruby client library for PuppetDB API'
  s.authors       = ['Vox Pupuli', 'Nathaniel Smith', 'Lindsey Smith']
  s.email         = 'info@puppetlabs.com'
  s.files         = Dir['CHANGELOG.md', 'README.md', 'LICENSE', 'lib/**/*']
  s.homepage      = 'https://github.com/voxpupuli/puppetdb-ruby'
  s.license       = 'apache'
  s.require_paths = ['lib']
  s.add_runtime_dependency 'httparty'
end
