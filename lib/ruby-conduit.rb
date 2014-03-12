require 'openssl'
require 'net/http'
require 'digest/sha1'

module Conduit
  VERSION = '0.1'

  def self.user_agent
    "ruby-conduit/#{VERSION}"
  end

  def self.http_headers
    {
      'User-Agent'   => user_agent,
      'Content-Type' => 'application/x-www-form-urlencoded'
    }
  end
end

require_relative 'conduit/config'
require_relative 'conduit/error'
require_relative 'conduit/session'
require_relative 'conduit/request'
require_relative 'conduit/response'

class Conduit::Test
  def self.connect!
    certificate = Conduit::Config.credentials['cert']
    auth_token  = Time.now.to_i

    data = {
      'authToken'     => auth_token,
      'authSignature' => hash(auth_token, certificate),
      'user'          => Conduit::Config.credentials['user']
    }

    session = Conduit::Session.new

    response = session.call 'conduit.connect', data

    Conduit::Session.new response['connectionID'],
      response['sessionKey']
  end

  private

  def self.hash(auth_token, certificate)
    Digest::SHA1.hexdigest "#{auth_token}#{certificate}"
  end
end

session = Conduit::Test.connect!

puts session.call 'differential.getrevision', revision_id: '1337'

