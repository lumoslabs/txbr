require 'txgh'

module Txbr
  class Project
    attr_reader :braze_api_url, :braze_api_key, :handler_id
    attr_reader :transifex_api_username, :transifex_api_password
    attr_reader :project_slug, :strings_format, :source_lang

    def initialize(options = {})
      @braze_api_url = options.fetch(:braze_api_url)
      @braze_api_key = options.fetch(:braze_api_key)
      @handler_id = options.fetch(:handler_id)
      @transifex_api_username = options.fetch(:transifex_api_username)
      @transifex_api_password = options.fetch(:transifex_api_password)
      @project_slug = options.fetch(:project_slug)
      @strings_format = options.fetch(:strings_format)
      @source_lang = options.fetch(:source_lang)
    end

    def braze_api
      @braze_api ||= Txbr::BrazeApi.new(braze_api_key, braze_api_url)
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
