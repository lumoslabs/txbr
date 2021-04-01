module Txbr
  class CampaignsApi
    CAMPAIGN_BATCH_SIZE = 100  # from braze docs
    CAMPAIGN_LIST_PATH = 'campaigns/list'.freeze
    CAMPAIGN_DETAILS_PATH = 'campaigns/details'.freeze

    attr_reader :braze_api

    def initialize(braze_api)
      @braze_api = braze_api
    end

    def each(&block)
      return to_enum(__method__) unless block_given?
      page = 0

      loop do
        campaigns = braze_api.get_json(CAMPAIGN_LIST_PATH, page: page, include_archived: false)
        campaigns['campaigns'].each(&block)
        break if campaigns['campaigns'].size < CAMPAIGN_BATCH_SIZE
        page += 1
      end
    end

    def details(campaign_id:)
      braze_api.get_json(CAMPAIGN_DETAILS_PATH, campaign_id: campaign_id)
    end
  end
end
