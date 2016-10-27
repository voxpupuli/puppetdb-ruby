Gem::Specification.new do |s|
  s.name          = 'puppetdb-ruby'
  s.version       = '0.0.2'
  s.summary       = "Simple Ruby client library for PuppetDB API"
  s.authors       = ["Nathaniel Smith", "Lindsey Smith", "Robin Bowes"]
  s.email         = 'info@puppetlabs.com'
  s.files         = `git ls-files`.split($/)
  s.homepage      = 'https://github.com/puppetlabs/puppetdb-ruby'
  s.license       = "apache"
  s.require_paths = ["lib"]
  
  s.add_runtime_dependency 'httparty'
end
