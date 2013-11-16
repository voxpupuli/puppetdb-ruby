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
client = PuppetDB::Client({:server => 'http://localhost:8080'})

# ssl
client = PuppetDB::Client({
    :server => 'https://localhost:8081',
    :pem    => {
        :key     => "keyfile",
        :cert    => "certfile",
        :ca_file => "cafile"
    }})

response = client.request('/facts', [:and,
                 [:'=', ['fact', 'kernel'], 'Linux'],
                 [:>, ['fact', 'uptime_days'], 30]]], {:limit => 10})
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

## Authors

Nathaniel Smith <nathaniel@puppetlabs.com>  
Lindsey Smith <lindsey@puppetlabs.com>

## License

See LICENSE.
