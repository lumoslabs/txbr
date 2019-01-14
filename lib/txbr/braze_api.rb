require 'faraday'
require 'faraday_middleware'

module Txbr
  class BrazeApi
    include RequestMethods

    attr_reader :api_key, :api_url

    def initialize(api_key, api_url, connection: nil)
      @api_key = api_key
      @api_url = api_url
      @connection = connection
    end

    def email_templates
      @email_templates ||= EmailTemplatesApi.new(self)
    end

    def campaigns
      @campaigns ||= CampaignsApi.new(self)
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
          faraday.adapter(:net_http)
        end
      end
    end
  end
end
