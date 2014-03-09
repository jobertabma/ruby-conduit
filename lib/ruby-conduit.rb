require 'uri'
require 'json'
require 'openssl'
require 'net/http'
require 'digest/sha1'

class ConduitError < Exception
end

class Conduit
  VERSION = '0.1'

  def self.connect!
    certificate = credentials['cert']
    auth_token  = Time.now.to_i

    data = {
      'authToken'     => auth_token,
      'authSignature' => hash(auth_token, certificate),
      'user'          => credentials['user']
    }

    session = call 'conduit.connect', data

    @connection_id = session['connectionID']
    @session_key   = session['sessionKey']

    true
  end

  def self.session
    {
      'sessionKey'   => @session_key,
      'connectionID' => @connection_id
    }
  end

  def self.connected?
    @session_key && @connection_id
  end

  def self.call(method, data = {})
    request = Net::HTTP::Post.new "#{conduit_uri.path}#{method}",
      static_http_headers

    request.set_form_data request_body(data)

    response = JSON.parse connection.request(request).body

    unless response['error_code'].nil?
      fail ConduitError, "#{response['error_info']} (#{response['error_code']})"
    end

    response['result']
  end

  def self.connection
    new_connection = Net::HTTP.new conduit_uri.host, conduit_uri.port

    new_connection.use_ssl = true
    new_connection.verify_mode = OpenSSL::SSL::VERIFY_NONE

    new_connection
  end

  private

  def self.static_http_headers
    {
      'User-Agent'   => user_agent,
      'Content-Type' => 'application/x-www-form-urlencoded'
    }
  end

  def self.conduit_uri
    URI.parse host
  end

  def self.user_agent
    "ruby-conduit/#{VERSION}"
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

  def self.config
    arcanist_config = File.expand_path '~/.arcrc'

    JSON.parse File.read(arcanist_config)
  end

  def self.hash(auth_token, certificate)
    Digest::SHA1.hexdigest "#{auth_token}#{certificate}"
  end

  def self.request_body(data = {})
    data.merge! __conduit__: session if connected?

    {
      'params'      => data.to_json,
      'output'      => 'json',
      'host'        => host,
      '__conduit__' => true
    }
  end
end

Conduit.connect!

puts Conduit.call 'differential.getrevision',
  revision_id: '1337'
