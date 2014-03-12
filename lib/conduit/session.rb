class Conduit::Session
  def initialize(connection_id = nil, session_key = nil)
    @connection_id = connection_id
    @session_key   = session_key
  end

  def call(method, data = {})
    Conduit::Request.new(self, method, data).response
      .result
  end

  def connected?
    @session_key && @connection_id
  end

  def session
    {
      'sessionKey'   => @session_key,
      'connectionID' => @connection_id
    }
  end
end
