class FakeEnv
  attr_reader :url

  def initialize(url)
    @url = url
  end
end

class FakeResponse
  attr_reader :env, :status, :body, :headers

  def initialize(url, status, body, headers)
    @env = FakeEnv.new(url)
    @status = status
    @body = body
    @headers = headers
  end
end

class FakeConnection
  class UnexpectedRequestError < StandardError; end

  attr_reader :interactions

  # of the form:
  # [{
  #    request: { verb: 'get', url: 'foo.com', params: { ... }, body: '...' },
  #    response: { status: 200, body: '...', headers: { ... } }
  # }]
  def initialize(interactions)
    @interactions = interactions
  end

  def get(url, params = {}, _headers = {})
    idx, interaction = find_interaction('get', url)
    raise UnexpectedRequestError, url unless interaction

    if interaction_params = interaction[:request][:params]
      raise UnexpectedRequestError, url unless params == interaction_params
    end

    interactions.delete_at(idx)
    response_for(url, interaction)
  end

  def post(url, body = '', _headers = {})
    idx, interaction = find_interaction('post', url)
    raise UnexpectedRequestError, url unless interaction

    if interaction_body = interaction[:request][:body]
      raise UnexpectedRequestError, url unless body == interaction_body
    end

    interactions.delete_at(idx)
    response_for(url, interaction)
  end

  private

  def response_for(url ,interaction)
    FakeResponse.new(
      url,
      interaction[:response][:status],
      interaction[:response][:body],
      interaction[:response][:headers]
    )
  end

  def find_interaction(verb, url)
    idx = interactions.find_index do |interaction|
      request = interaction[:request]
      request[:verb] == verb && request[:url] == url
    end

    return [nil, nil] unless idx
    [idx, interactions[idx]]
  end
end
