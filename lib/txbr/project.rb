require 'txgh'

module Txbr
  class Project
    attr_reader :braze_api_url, :braze_api_key, :handler_id
    attr_reader :transifex_api_username, :transifex_api_password
    attr_reader :project_slug, :strings_format, :source_lang

    # @TODO: remove these when Braze gives us the endpoints we asked for
    attr_reader :session_id, :app_group_id

    def initialize(options = {})
      @braze_api_url = options.fetch(:braze_api_url)
      @braze_api_key = options.fetch(:braze_api_key)
      @handler_id = options.fetch(:handler_id)
      @transifex_api_username = options.fetch(:transifex_api_username)
      @transifex_api_password = options.fetch(:transifex_api_password)
      @project_slug = options.fetch(:project_slug)
      @strings_format = options.fetch(:strings_format)
      @source_lang = options.fetch(:source_lang)

      # @TODO: remove these when Braze gives us the endpoints we asked for
      @session_id = options.fetch(:session_id)
      @app_group_id = options.fetch(:app_group_id)
    end

    def braze_api
      # @TODO: use BrazeApi when Braze gives us the endpoints we asked for
      # @braze_api ||= Txbr::BrazeApi.new(braze_api_key, braze_api_url)
      @braze_api ||= Txbr::BrazeSessionApi.new(braze_api_url, session_id, app_group_id)
    end

    def transifex_api
      @transifex_api ||= Txgh::TransifexApi.create_from_credentials(
        transifex_api_username, transifex_api_password
      )
    end

    def handler
      @handler ||= Txbr.handler_for(self)
    end
  end
end
