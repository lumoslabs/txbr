require 'faraday'
require 'faraday_middleware'

module Txbr
  class BrazeApi
    TEMPLATE_BATCH_SIZE = 35
    TEMPLATE_LIST_PATH = 'templates/email/list'.freeze
    TEMPLATE_INFO_PATH = 'templates/email/info'.freeze

    include RequestMethods

    attr_reader :api_key, :api_url

    def initialize(api_key, api_url, connection: nil)
      @api_key = api_key
      @api_url = api_url
      @connection = connection
    end

    def each_email_template(offset: 1, &block)
      return to_enum(__method__, offset: offset) unless block_given?

      loop do
        templates = get_json(
          TEMPLATE_LIST_PATH,
          offset: offset,
          limit: TEMPLATE_BATCH_SIZE
        )

        templates['templates'].each(&block)
        offset += templates['templates'].size
        break if templates['templates'].size < TEMPLATE_BATCH_SIZE
      end
    end

    def get_email_template_details(email_template_id:)
      get_json(TEMPLATE_INFO_PATH, email_template_id: email_template_id)
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
