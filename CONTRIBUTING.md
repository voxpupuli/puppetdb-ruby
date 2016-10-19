This library has grown over time based on a range of contributions from
people using it. If you follow these contributing guidelines your patch
will likely make it into a release a little quicker.


## Contributing

Please note that this project is released with a Contributor Code of Conduct.
By participating in this project you agree to abide by its terms. [Contributor
Code of Conduct](https://voxpupuli.org/coc/).

1. Fork the repo.

1. Create a separate branch for your change.

1. Run the tests. We only take pull requests with passing tests, and
   documentation.

1. Add a test for your change. Only refactoring and documentation
   changes require no new tests. If you are adding functionality
   or fixing a bug, please add a test.

1. Squash your commits down into logical components. Make sure to rebase
   against the current master.

1. Push the branch to your fork and submit a pull request.

Please be prepared to repeat some of these steps as our contributors review
your code.

## Dependencies

The testing and development tools have a bunch of dependencies,
all managed by [bundler](http://bundler.io/) according to the
[Puppet support matrix](http://docs.puppetlabs.com/guides/platforms.html#ruby-versions).

Install the dependencies like so...

    bundle install


## Running the unit tests

The unit test suite covers most of the code, as mentioned above please
add tests if you're adding new functionality.

To run your all the unit tests

    bundle exec rspec spec

To run a specific spec test

    bundle exec rspec spec/foo_spec.rb
