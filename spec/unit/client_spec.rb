require File.join(File.dirname(__FILE__), '..', 'spec_helper')
require File.join(File.dirname(__FILE__), '..', '..', 'lib', 'puppetdb')

def make_mock_response
  m = mock
  m.stubs(:code).returns(200)
  m.expects(:parsed_response).returns(['foo'])
  m
end

def make_mock_query
  m = mock
  m.expects(:build)
  m.expects(:summarize_by).returns(m)
  m
end

def expect_include_total(mock_query)
  mock_query.expects(:include_total).with(true)
  mock_query
end

describe 'raise_if_error' do
  settings = { 'server' => 'http://localhost:8080' }

  it 'works with 4xx' do
    response = mock
    response.stubs(:code).returns(400)

    -> { PuppetDB::Client.new(settings).raise_if_error(response) }.should raise_error(PuppetDB::APIError)
  end

  it 'works with 5xx' do
    response = mock
    response.stubs(:code).returns(500)

    -> { PuppetDB::Client.new(settings).raise_if_error(response) }.should raise_error(PuppetDB::APIError)
  end

  it 'raises UnauthorizedError with 401' do
    response = mock
    response.stubs(:code).returns(401)

    -> { PuppetDB::Client.new(settings).raise_if_error(response) }.should raise_error(PuppetDB::UnauthorizedError)
  end

  it 'raises ForbiddenError with 403' do
    response = mock
    response.stubs(:code).returns(403)

    -> { PuppetDB::Client.new(settings).raise_if_error(response) }.should raise_error(PuppetDB::ForbiddenError)
  end

  it 'ignores 2xx' do
    response = mock
    response.stubs(:code).returns(200)

    -> { PuppetDB::Client.new(settings).raise_if_error(response) }.should_not raise_error
  end

  it 'ignores 3xx' do
    response = mock
    response.stubs(:code).returns(300)

    -> { PuppetDB::Client.new(settings).raise_if_error(response) }.should_not raise_error
  end
end

describe 'SSL support' do
  describe 'when http:// is specified' do
    it 'does not use ssl' do
      settings = {
        'server' => 'http://localhost:8080'
      }

      r = PuppetDB::Client.new(settings)
      expect(r.use_ssl).to eq(false)
    end
  end

  describe 'when https:// is specified' do
    it 'uses ssl' do
      settings = {
        'server' => 'https://localhost:8081',
        'pem' => {
          'cert'    => 'foo',
          'key'     => 'bar',
          'ca_file' => 'baz'
        }
      }

      r = PuppetDB::Client.new(settings)
      expect(r.use_ssl).to eq(true)
    end

    it 'tolerates lack of pem' do
      settings = {
        server: 'https://localhost:8081'
      }

      -> { PuppetDB::Client.new(settings) }.should_not raise_error
    end

    it 'does not tolerate lack of key' do
      settings = {
        'server' => 'https://localhost:8081',
        'pem'    => {
          'cert' => 'foo',
          'ca_file' => 'bar'
        }
      }

      -> { PuppetDB::Client.new(settings) }.should raise_error(RuntimeError)
    end

    it 'does not tolerate lack of cert' do
      settings = {
        'server' => 'https://localhost:8081',
        'pem'    => {
          'key' => 'foo',
          'ca_file' => 'bar'
        }
      }

      -> { PuppetDB::Client.new(settings) }.should raise_error(RuntimeError)
    end

    it 'does not tolerate lack of ca_file' do
      settings = {
        'server' => 'https://localhost:8081',
        'pem'    => {
          'key' => 'foo',
          'cert' => 'bar'
        }
      }

      -> { PuppetDB::Client.new(settings) }.should raise_error(RuntimeError)
    end

    context 'when using token auth' do
      settings = {
        'server' => 'https://localhost:8081'
      }

      before do
        Dir.stubs(:home).returns('/user/root')
        File.stubs(:readable?).with('/etc/puppetlabs/client-tools/puppetdb.conf').returns(false)
        File.stubs(:readable?).with('/user/root/.puppetlabs/client-tools/puppetdb.conf').returns(false)
        File.stubs(:readable?).with('/user/root/.puppetlabs/token').returns(true)
        File.stubs(:read).with('/user/root/.puppetlabs/token').returns('mytoken')
      end

      it 'does not raise an error when no token or pem is provided' do
        -> { PuppetDB::Client.new(settings) }.should_not raise_error
      end

      it 'configures the header with the token' do
        r = PuppetDB::Client.new(settings)
        expect(r.class.headers).to include('X-Authentication' => 'mytoken')
      end

      it 'will set an empty pem' do
        r = PuppetDB::Client.new(settings)
        expect(r.class.default_options).to include(pem: {})
      end

      it 'uses the default cacert path' do
        r = PuppetDB::Client.new(settings)
        expect(r.class.default_options).to include(cacert: '/etc/puppetlabs/puppet/ssl/certs/ca.pem')
      end

      it 'will use a provided cacert path' do
        r = PuppetDB::Client.new(settings.merge('cacert' => '/my/ca/path'))
        expect(r.class.default_options).to include(cacert: '/my/ca/path')
      end
    end
  end

  describe 'when a protocol is missing from config file' do
    it 'raises an exception' do
      settings = {
        'server' => 'localhost:8080'
      }

      -> { PuppetDB::Client.new(settings) }.should raise_error(RuntimeError)
    end
  end
end

describe 'request' do
  settings = { server: 'http://localhost' }

  it 'works with array instead of Query' do
    client = PuppetDB::Client.new(settings)

    mock_response = mock
    mock_response.expects(:code).at_least_once.returns(200)
    mock_response.expects(:headers).returns('X-Records' => 0)
    mock_response.expects(:parsed_response).returns([])

    PuppetDB::Client.expects(:get).returns(mock_response).at_least_once.with do |_path, opts|
      opts[:body] == { 'query' => '[1,2,3]' }
    end
    client.request('/foo', [1, 2, 3])
  end

  it 'processes options correctly' do
    client = PuppetDB::Client.new(settings)

    mock_response = mock
    mock_response.expects(:code).at_least_once.returns(200)
    mock_response.expects(:headers).returns('X-Records' => 0)
    mock_response.expects(:parsed_response).returns([])

    PuppetDB::Client.expects(:get).returns(mock_response).at_least_once.with do |_path, opts|
      opts == {
        body: {
          'query'         => '[1,2,3]',
          'limit'         => 10,
          'counts_filter' => '[4,5,6]',
          'foo_bar'       => 'foo'
        }
      }
    end

    client.request('/foo', PuppetDB::Query[1, 2, 3], limit: 10,
                                                     counts_filter: [4, 5, 6],
                                                     foo_bar: 'foo')
  end

  it 'supports pql' do
    client = PuppetDB::Client.new(settings)

    mock_response = mock
    mock_response.expects(:code).at_least_once.returns(200)
    mock_response.expects(:headers).returns('X-Records' => 0)
    mock_response.expects(:parsed_response).returns([])

    PuppetDB::Client.expects(:get).returns(mock_response).at_least_once.with do |_path, opts|
      opts == {
        body: {
          'query'         => 'resources{}'
        }
      }
    end

    client.request('', 'resources{}')
  end
end

describe 'command' do
  settings = { server: 'http://localhost' }
  command = 'deactivate node'
  payload = { 'certname' => 'test1', 'producer_timestamp' => '2015-01-01' }
  payload_version = 3

  it 'processes options correctly' do
    client = PuppetDB::Client.new(settings)

    mock_response = mock
    mock_response.expects(:code).at_least_once.returns(200)
    mock_response.expects(:parsed_response).returns([])

    PuppetDB::Client.expects(:post).returns(mock_response).at_least_once.with do |_path, opts|
      expect(opts).to eq(query: {
                           'command' => command,
                           'version' => payload_version,
                           'certname' => 'test1'
                         },
                         body: payload.to_json,
                         headers: {
                           'Accept' => 'application/json',
                           'Content-Type' => 'application/json'
                         })
    end
    client.command(command, payload, payload_version)
  end
end
