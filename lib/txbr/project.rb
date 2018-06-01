require 'txgh'

module Txbr
  class Project
    attr_reader :braze_api_url, :braze_api_key, :handler_id
    attr_reader :strings_format, :source_lang

    # @TODO: remove these when Braze gives us the endpoints we asked for
    attr_reader :braze_app_group_id, :braze_email_address, :braze_password

    def initialize(options = {})
      @braze_api_url = options.fetch(:braze_api_url)
      @braze_api_key = options.fetch(:braze_api_key)
      @handler_id = options.fetch(:handler_id)
      @strings_format = options.fetch(:strings_format)
      @source_lang = options.fetch(:source_lang)

      # @TODO: remove these when Braze gives us the endpoints we asked for
      @braze_app_group_id = options.fetch(:braze_app_group_id)
      @braze_email_address = options.fetch(:braze_email_address)
      @braze_password = options.fetch(:braze_password)

      @braze_api = options[:braze_api]
      @transifex_api = options[:transifex_api]
    end

    def braze_session
      @@braze_session ||= Txbr::BrazeSession.new(
        braze_api_url, braze_email_address, braze_password
      )
    end

    def braze_api
      # @TODO: use BrazeApi when Braze gives us the endpoints we asked for
      # @braze_api ||= Txbr::BrazeApi.new(braze_api_key, braze_api_url)
      @braze_api ||= Txbr::BrazeSessionApi.new(braze_session, braze_app_group_id)
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
