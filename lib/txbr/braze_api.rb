require 'faraday'
require 'faraday_middleware'

module Txbr
  class BrazeApi
    include RequestMethods

    attr_reader :api_key, :api_url

    def initialize(api_key, api_url)
      @api_key = api_key
      @api_url = api_url
    end

    def each_email_template
      raise NotImplementedError, 'Braze does not support this operation yet'
    end

    def get_email_template_details(email_template_id:)
      raise NotImplementedError, 'Braze does not support this operation yet'
    end

    private

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
