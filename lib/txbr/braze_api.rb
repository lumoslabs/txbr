require 'faraday'
require 'faraday_middleware'

module Txbr
  class BrazeApiError < StandardError; end
  class BrazeUnauthorizedError < BrazeApiError; end
  class BrazeNotFoundError < BrazeApiError; end

  class BrazeApi
    attr_reader :api_key, :api_url

    def initialize(api_key, api_url)
      @api_key = api_key
      @api_url = api_url
    end

    def list_email_templates
      get_json('templates/email/list')
    end

    def get_email_template(email_template_id:)
      params = { email_template_id: email_template_id }
      get_json('templates/email/get', params)
    end

    private

    def get_json(url, params)
      response = get(url, params)
      JSON.parse(response.body)
    end

    def get(url, params)
      response = connection.get(url, params)
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

    def connection
      @connection ||= begin
        options = {
          url: api_url,
          params: { api_key: api_key },
          headers: { Accept: 'application/json' }
        }

        Faraday.new(options) do |faraday|
          faraday.request(:json)
          faraday.response(:logger)
          faraday.use(FaradayMiddleware::FollowRedirects)
          faraday.adapter(Faraday.default_adapter)
        end
      end
    end
  end
end
