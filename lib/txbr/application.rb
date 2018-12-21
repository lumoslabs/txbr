require 'abroad'
require 'json'
require 'sinatra/json'
require 'txgh'

module Txbr
  class Application < Sinatra::Base
    TARGET_FORMAT = 'json/dotted-key'.freeze
    REQUIRED_PARAMS = %w(project_slug resource_slug locale strings_format).freeze

    get '/strings.json' do
      begin
        REQUIRED_PARAMS.each do |required_param|
          unless params.include?(required_param)
            status 400
            return json(error: "Missing parameter '#{required_param}'")
          end
        end

        transifex_client = Txgh::TransifexApi.create_from_credentials(
          Txbr::Config.transifex_api_username,
          Txbr::Config.transifex_api_password
        )

        source = transifex_client.download(
          params[:project_slug], params[:resource_slug], params[:locale]
        )

        target = StringIO.new
        strings_format = Txgh::ResourceContents::EXTRACTOR_MAP[params[:strings_format]]

        Abroad.serializer(TARGET_FORMAT).from_stream(target, params[:locale]) do |serializer|
          Abroad.extractor(strings_format)
            .from_string(source)
            .extract_each do |key, value|
              serializer.write_key_value(key, value)
            end
        end

        status 200
        json(JSON.parse(target.string))
      rescue StandardError => e
        status 500
        json(error: e.message)
      end
    end
  end
end
