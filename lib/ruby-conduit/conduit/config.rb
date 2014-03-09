require 'uri'

class Conduit::Config
  def self.conduit_uri
    URI.parse host
  end

  def self.conduit_host
    config['hosts'].first
  end

  def self.host
    conduit_host[0]
  end

  def self.credentials
    conduit_host[1]
  end

  private

  def self.config
    arcanist_config = File.expand_path '~/.arcrc'

    JSON.parse File.read(arcanist_config)
  end
end
