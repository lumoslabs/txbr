module Txbr
  module RequestMethods
    def get_json(url, params = {})
      response = get(url, params)
      JSON.parse(response.body)
    end

    def post_json(url, body = {})
      response = post(url, body.to_json)
      JSON.parse(response.body)
    end

    def get(url, params = {})
      act(:get, url, params)
    end

    def post(url, body)
      act(:post, url, body)
    end

    def act(verb, *args)
      connection.send(verb, *args).tap do |response|
        raise_error!(response)
      end
    end

    def raise_error!(response)
      case response.status
        when 401
          raise BrazeUnauthorizedError, "401 Unauthorized: #{response.env.url}"
        when 404
          raise BrazeNotFoundError, "404 Not Found: #{response.env.url}"
        else
          if (response.status / 100) != 2
            raise Txbr::BrazeApiError.new(
              "HTTP #{response.status}: #{response.env.url}, body: #{response.body}",
              response.status
            )
          end
      end
    end
  end
end
