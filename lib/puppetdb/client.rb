require 'httparty'
require 'logger'

require 'puppetdb/error'

module PuppetDB
  class FixSSLConnectionAdapter < HTTParty::ConnectionAdapter
    def attach_ssl_certificates(http, options)
      if options[:pem].empty?
        http.ca_file = options[:cacert]
      else
        http.cert    = OpenSSL::X509::Certificate.new(File.read(options[:pem]['cert']))
        http.key     = OpenSSL::PKey::RSA.new(File.read(options[:pem]['key']))
        http.ca_file = options[:pem]['ca_file']
      end
      http.verify_mode = OpenSSL::SSL::VERIFY_PEER
    end
  end

  class Client
    include HTTParty
    attr_reader :use_ssl
    attr_writer :logger

    def hash_includes?(hash, *sought_keys)
      sought_keys.each { |x| return false unless hash.include?(x) }
      true
    end

    def debug(msg)
      @logger.debug(msg) if @logger
    end

    def initialize(settings = {}, query_api_version = 4, command_api_version = 1)
      config = Config.new(settings, load_files: true)
      @query_api_version = query_api_version
      @command_api_version = command_api_version

      server = config.server
      pem    = config['pem'] || {}
      token  = config.token

      scheme = URI.parse(server).scheme

      unless %w[http https].include? scheme
        error_msg = 'Configuration error: :server must specify a protocol of either http or https'
        raise error_msg
      end

      @use_ssl = scheme == 'https'
      if @use_ssl
        unless pem.empty? || hash_includes?(pem, 'key', 'cert', 'ca_file')
          error_msg = 'Configuration error: https:// specified with pem, but pem is incomplete. It requires cert, key, and ca_file.'
          raise error_msg
        end

        self.class.default_options = { pem: pem, cacert: config['cacert'] }
        self.class.headers('X-Authentication' => token) if token
        self.class.connection_adapter(FixSSLConnectionAdapter)
      end

      self.class.base_uri(server)
    end

    def raise_if_error(response)
      raise UnauthorizedError, response if response.code == 401
      raise ForbiddenError, response if response.code == 403
      raise APIError, response if response.code.to_s =~ %r{^[4|5]}
    end

    def request(endpoint, query, opts = {})
      path = "/pdb/query/v#{@query_api_version}"
      if endpoint == ''
        # PQL
        json_query = query
      else
        path += "/#{endpoint}"
        query = PuppetDB::Query.maybe_promote(query)
        json_query = query.build
      end

      filtered_opts = {}
      opts.each do |k, v|
        key = k.to_s
        # Per https://puppet.com/docs/puppetdb/7/api/query/v4/upgrading-from-v3.html#changes-affecting-all-endpoints
        # all query params will use _ in APIv4
        key.sub!('_', '-') if @query_api_version < 4

        # PuppetDB expects JSON-encoded data for parameters with
        # structured data:
        value = (v.is_a?(Array) || v.is_a?(Hash)) ? JSON.dump(v) : v
        filtered_opts[key] = value
      end

      debug("#{path} #{json_query} #{filtered_opts}")
      filtered_opts['query'] = json_query

      ret = self.class.get(path, body: filtered_opts)
      raise_if_error(ret)

      total = ret.headers['X-Records']
      total = ret.parsed_response.length if total.nil?

      Response.new(ret.parsed_response, total)
    end

    def command(command, payload, version)
      path = "/pdb/cmd/v#{@command_api_version}"

      query = {
        'command' => command,
        'version' => version,
        'certname' => payload['certname']
      }

      debug("#{path} #{query} #{payload}")

      ret = self.class.post(
        path,
        query: query,
        body: payload.to_json,
        headers: {
          'Accept'       => 'application/json',
          'Content-Type' => 'application/json'
        }
      )
      raise_if_error(ret)

      Response.new(ret.parsed_response)
    end
  end
end
