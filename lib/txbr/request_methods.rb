module Txbr
  module RequestMethods
    private

    def get_json(url, params = {})
      response = get(url, params)
      JSON.parse(response.body)
    end

    def post_json(url, body = {})
      response = post(url, body.to_json)
      JSON.parse(response.body)
    end

    def get(url, params = {})
      response = connection.get(url, params)
      raise_error!(response)
      response
    end

    def post(url, body)
      response = connection.post(url, body)
      raise_error!(response)
      response
    end

    def raise_error!(response)
      case response.status
        when 401
          raise BrazeUnauthorizedError, "401 Unauthorized: #{response.env.url}"
        when 404
          raise BrazeNotFoundError, "404 Not Found: #{response.env.url}"
        else
          if (response.status / 100) != 2
            raise TransifexApiError.new(
              "HTTP #{response.status}: #{response.env.url}, body: #{response.body}",
              response.status
            )
          end
      end
    end
  end
end
