# puppetdb-ruby

a simple gem for interacting with the
[PuppetDB](https://github.com/puppetlabs/puppetdb) API.

This library was migrated from [puppetlabs](https://github.com/puppetlabs)
ownership to VoxPupuli on 19 October 2016.

## Installation

Installing from Ruby CLI:
```
gem install puppetdb-ruby
```

Include in Gemfile:
``` ruby
gem 'puppetdb-ruby'
```

## Usage

Require the puppetdb gem in your ruby code.

```ruby
require 'puppetdb'

# Defaults to latest API version.
```

#### Create a new connection:

Non-SSL:
``` ruby
client = PuppetDB::Client.new({:server => 'http://localhost:8080'})
```

SSL:
``` ruby
client = PuppetDB::Client.new({
    :server => 'https://localhost:8081',
    :pem    => {
        'key'     => "keyfile",
        'cert'    => "certfile",
        'ca_file' => "cafile"
    }})
```

#### Query API usage

The Query Feature allows the user to request data from PuppetDB using the Query endpoints. It defaults to the latest version of the Query Endpoint.

Currently, `puppetdb-ruby` only supports the [AST Query Language](https://docs.puppet.com/puppetdb/5.0/api/query/v4/ast.html).

Support for the [PQL Query Language](https://docs.puppet.com/puppetdb/5.0/api/query/tutorial-pql.html) is planned for a future release.

Example:
``` ruby
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

See the [PuppetDB API Docs](https://docs.puppet.com/puppetdb/5.0/api/index.html) for more.


#### PQL Queries usage

PQL queries are supported by using the empty endpoint.

Example:
``` ruby
response = client.request(
  '',
  'resources[title] { nodes { deactivated is null } }',
  {:limit => 10}
)

resources = response.data
```

See the [PuppetDB API Docs](https://docs.puppet.com/puppetdb/5.0/api/query/v4/pql.html) for more on PQL queries.


#### Command API Usage

The Command Feature allows the user to execute REST Commands against the PuppetDB Command API Endpoints. It defaults to the latest version of the Command Endpoint.

The command method takes three arguments:

* `command`: a string identifying the command
* `payload`: a valid JSON object of any sort. It’s up to an individual handler function to determine how to interpret that object.
* `version`: a JSON integer describing what version of the given command you’re attempting to invoke. The version of the command also indicates the version of the wire format to use for the command.

Example:
``` ruby
client.command(
  'deactivate node',
  {'certname' => 'test1', 'producer_timestamp' => '2015-01-01'},
  3
)
```

See the PuppetDB [Commands Endpoint Docs](https://docs.puppet.com/puppetdb/5.0/api/command/v1/commands.html) for more information.

## Tests

```
bundle install
bundle exec rspec
```

## Issues & Contributions

File issues or feature requests using [GitHub
issues](https://github.com/voxpupuli/puppetdb-ruby/issues).

If you are interested in contributing to this project, please see the
[Contribution Guidelines](CONTRIBUTING.md)

## Authors

This module was donated to VoxPupuli by Puppet Inc on 10-19-2016.

Nathaniel Smith <nathaniel@puppetlabs.com>
Lindsey Smith <lindsey@puppetlabs.com>
Ruth Linehan <ruth@puppetlabs.com>

## License

See LICENSE.
