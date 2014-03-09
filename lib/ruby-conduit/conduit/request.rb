class Conduit::Request
  def initialize(session, method, data)
    @session = session

    @response = call(method, data)
  end

  def response
    @response
  end

  private

  def session
    @session
  end

  def call(method, data)
    request = Net::HTTP::Post.new route(method),
      Conduit.http_headers

    request.set_form_data body(data)

    response = connection.request(request).body

    Conduit::Response.new response
  end

  def route(method)
    "#{Conduit::Config.conduit_uri.path}#{method}"
  end

  def connection
    new_connection = Net::HTTP.new Conduit::Config.conduit_uri.host,
      Conduit::Config.conduit_uri.port

    new_connection.use_ssl = true
    new_connection.verify_mode = OpenSSL::SSL::VERIFY_NONE

    new_connection
  end

  def body(data)
    if session.connected?
      data.merge! __conduit__: session.session
    end

    {
      'params'      => data.to_json,
      'output'      => 'json',
      'host'        => Conduit::Config.host,
      '__conduit__' => true
    }
  end
end
