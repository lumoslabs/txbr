module Txbr
  class EmailTemplatesApi
    TEMPLATE_BATCH_SIZE = 35
    TEMPLATE_LIST_PATH = 'templates/email/list'.freeze
    TEMPLATE_DETAILS_PATH = 'templates/email/info'.freeze

    attr_reader :braze_api

    def initialize(braze_api)
      @braze_api = braze_api
    end

    def each(offset: 1, &block)
      return to_enum(__method__, offset: offset) unless block_given?

      loop do
        templates = braze_api.get_json(
          TEMPLATE_LIST_PATH,
          offset: offset,
          limit: TEMPLATE_BATCH_SIZE
        )

        templates['templates'].each(&block)
        offset += templates['templates'].size
        break if templates['templates'].size < TEMPLATE_BATCH_SIZE
      end
    end

    def details(email_template_id:)
      braze_api.get_json(TEMPLATE_DETAILS_PATH, email_template_id: email_template_id)
    end
  end
end
