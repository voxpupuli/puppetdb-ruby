Unmaintained: This project is not supported or maintained by Puppet and is
incompatible with recent versions of PuppetDB.

# puppetdb-ruby

a simple gem for interacting with the
[PuppetDB](https://github.com/puppetlabs/puppetdb) API.

## Installation

gem install puppetdb-ruby

## Usage

```ruby
require 'puppetdb'

# Defaults to latest API version.

# non-ssl
client = PuppetDB::Client.new({:server => 'http://localhost:8080'})

# ssl
client = PuppetDB::Client.new({
    :server => 'https://localhost:8081',
    :pem    => {
        'key'     => "keyfile",
        'cert'    => "certfile",
        'ca_file' => "cafile"
    }})

response = client.request(
  'nodes',
  [:and,
    [:'=', ['fact', 'kernel'], 'Linux'],
    [:>, ['fact', 'uptime_days'], 30]
  ],
  {:limit => 10}
)

nodes = response.data

# queries are composable

uptime = PuppetDB::Query[:>, [:fact, 'uptime_days'], 30]
redhat = PuppetDB::Query[:'=', [:fact, 'osfamily'], 'RedHat']
debian = PuppetDB::Query[:'=', [:fact, 'osfamily'], 'Debian']

client.request uptime.and(debian)
client.request uptime.and(redhat)
client.request uptime.and(debian.or(redhat))
```

## Tests

bundle install
bundle exec rspec

## Issues & Contributions

File issues or feature requests using [GitHub
issues](https://github.com/puppetlabs/puppetdb-ruby/issues).

If you are interested in contributing to this project, please see the
[Contribution Guidelines](CONTRIBUTING.md)

## Authors

Nathaniel Smith <nathaniel@puppetlabs.com>
Lindsey Smith <lindsey@puppetlabs.com>
Ruth Linehan <ruth@puppetlabs.com>

## License

See LICENSE.
