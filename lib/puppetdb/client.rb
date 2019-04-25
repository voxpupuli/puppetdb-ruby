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

    def initialize(settings = {}, query_api_version = 4, command_api_version = 1, admin_api_version = 1)
      config = Config.new(settings, load_files: true)
      @query_api_version = query_api_version
      @command_api_version = command_api_version
      @admin_api_version = admin_api_version

      @servers = config.server_urls
      pem    = config['pem'] || {}
      token  = config.token

      @servers.each do |server|
        scheme = URI.parse(server).scheme
        @use_ssl ||= scheme == 'https'

        unless %w[http https].include? scheme
          error_msg = "Configuration error: server_url '#{server}' must specify a protocol of either http or https"
          raise error_msg
        end
      end

      return unless @use_ssl
      unless pem.empty? || hash_includes?(pem, 'key', 'cert', 'ca_file')
        error_msg = 'Configuration error: https:// specified with pem, but pem is incomplete. It requires cert, key, and ca_file.'
        raise error_msg
      end

      self.class.default_options = { pem: pem, cacert: config['cacert'] }
      self.class.headers('X-Authentication' => token) if token
      self.class.connection_adapter(FixSSLConnectionAdapter)
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

      query_mode = opts.delete(:query_mode) || :first
      filtered_opts = { 'query' => json_query }
      opts.each do |k, v|
        if k == :counts_filter
          filtered_opts['counts-filter'] = JSON.dump(v)
        else
          filtered_opts[k.to_s.sub('_', '-')] = v
        end
      end

      debug("#{path} #{json_query} #{opts}")

      if query_mode == :first
        self.class.base_uri(@servers.first)
        ret = self.class.get(path, body: filtered_opts)
        raise_if_error(ret)

        total = ret.headers['X-Records']
        total = ret.parsed_response.length if total.nil?

        Response.new(ret.parsed_response, total)
      elsif query_mode == :failover

        ret=nil
        @servers.each do |server|
          self.class.base_uri(server)
          ret = self.class.get(path, body: filtered_opts)
          if ret.code < 400
            total = ret.headers['X-Records']
            total = ret.parsed_response.length if total.nil?

            return Response.new(ret.parsed_response, total)
          else
            debug("query on '#{server}' failed with #{ret.code}")
          end
        end
        raise APIError, ret
      else
        raise ArgumentError, "Query mode '#{query_mode}' is not supported (try :first or :failover)."
      end
    end

    def command(command, payload, version)
      path = "/pdb/cmd/v#{@command_api_version}"

      query = {
        'command' => command,
        'version' => version,
        'certname' => payload['certname']
      }

      debug("#{path} #{query} #{payload}")

      self.class.base_uri(@servers.first)
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

    def export(filename, opts = {})
      self.class.base_uri(@servers.first)
      path = "/pdb/admin/v#{@admin_api_version}/archive"

      # Allow opts to override anonymization_profile, but enforce
      # stream_body to avoid using memory
      params = { anonymization_profile: 'none' }.
               merge(opts).
               merge(stream_body: true)

      File.open(filename, 'w') do |file|
        self.class.get(path, params) do |fragment|
          if [301, 302].include?(fragment.code)
            debug 'Skip streaming write for redirect'
          elsif fragment.code == 200
            file.write(fragment)
          else
            raise StandardError, "Non-success status code while streaming #{fragment.code}"
          end
        end
      end
    end

    def import(filename)
      self.class.base_uri(@servers.first)
      path = "/pdb/admin/v#{@admin_api_version}/archive"
      self.class.post(path, body: { archive: File.open(filename) })
    end

    def status
      status_endpoint = '/status/v1/services'
      status_map = {}

      @servers.each do |server|
        self.class.base_uri(server)
        ret = self.class.get(status_endpoint)

        status_map[server] = if ret.code >= 400
                               { error: "Unable to build JSON object from server: #{server}" }
                             else
                               ret.parsed_response
                             end
      end
      status_map
    end
  end
end
