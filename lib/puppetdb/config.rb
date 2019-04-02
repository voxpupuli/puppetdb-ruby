require 'json'

class PuppetDB::Config
  def initialize(overrides = nil, load_files = false)
    @overrides = {}
    overrides.each { |k, v| @overrides[k.to_s] = v } unless overrides.nil?

    @load_files = load_files
  end

  def load_file(path)
    File.open(path) { |f| JSON.parse(f.read)['puppetdb'] }
  end

  def puppetlabs_root
    '/etc/puppetlabs'
  end

  def global_conf
    File.join(puppetlabs_root, 'client-tools', 'puppetdb.conf')
  end

  def user_root
    File.join(Dir.home, '.puppetlabs')
  end

  def user_conf
    File.join(user_root, 'client-tools', 'puppetdb.conf')
  end

  def default_cacert
    "#{puppetlabs_root}/puppet/ssl/certs/ca.pem"
  end

  def defaults
    {
      'cacert' => default_cacert,
      'token-file' => File.join(user_root, 'token')
    }
  end

  def load_config
    config = defaults
    if @load_files
      if File.exist?(global_conf) && File.readable?(global_conf)
        config = config.merge(load_file(global_conf))
      end

      if @overrides['config-file']
        config = config.merge(load_file(@overrides['config-file']))
      elsif File.exist?(user_conf) && File.readable?(user_conf)
        config = config.merge(load_file(user_conf))
      end
    end

    config.merge(@overrides)
  end

  def config
    @config ||= load_config
  end

  def load_token
    if @config.include?('token')
      @config['token']
    elsif File.readable?(config['token-file'])
      File.read(config['token-file']).strip
    end
  end

  def token
    @token ||= load_token
  end

  def server_urls
    return [config['server']] unless config['server'].nil?
    return config['server_urls'].split(',') if config['server_urls'].is_a?(String)
    config['server_urls'] || []
  end

  def server
    server_urls.first || {}
  end

  def [](key)
    @config[key]
  end
end
