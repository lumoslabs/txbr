require 'txgh'

module Txbr
  class Project
    attr_reader :braze_api_url, :braze_api_key, :handler_id
    attr_reader :strings_format, :source_lang

    def initialize(options = {})
      @braze_api_url = options.fetch(:braze_api_url)
      @braze_api_key = options.fetch(:braze_api_key)
      @handler_id = options.fetch(:handler_id)
      @strings_format = options.fetch(:strings_format)
      @source_lang = options.fetch(:source_lang)

      @braze_api = options[:braze_api]
      @transifex_api = options[:transifex_api]
    end

    def braze_api
      @braze_api ||= Txbr::BrazeApi.new(braze_api_key, braze_api_url)
    end

    def transifex_api
      @transifex_api ||= Txgh::TransifexApi.create_from_credentials(
        Txbr::Config.transifex_api_username,
        Txbr::Config.transifex_api_password
      )
    end

    def handler
      @handler ||= Txbr.handler_for(self)
    end
  end
end
