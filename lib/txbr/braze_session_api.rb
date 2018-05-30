require 'faraday'
require 'faraday_middleware'

module Txbr
  class BrazeSessionApi
    include RequestMethods

    attr_reader :api_url, :session_id, :app_group_id

    def initialize(api_url, session_id, app_group_id)
      @api_url = api_url
      @session_id = session_id
      @app_group_id = app_group_id
    end

    def list_email_templates
      get_json('engagement/email_templates', start: 0, limit: 35)
    end

    def get_email_template(email_template_id:)
      get_json("/engagement/email_templates/#{email_template_id}")
    end

    private

    def connection
      @connection ||= begin
        options = {
          url: api_url,
          params: { app_group_id: app_group_id },
          headers: { cookie: "_session_id=#{session_id}" }
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
