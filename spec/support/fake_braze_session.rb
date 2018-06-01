class FakeBrazeSession
  attr_reader :api_url, :session_id, :was_reset
  alias reset? was_reset

  def initialize(api_url, session_id)
    @api_url = api_url
    @session_id = session_id
    @was_reset = false
  end

  def reset!
    @was_reset = true
  end
end
