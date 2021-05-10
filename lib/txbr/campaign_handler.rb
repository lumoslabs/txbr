module Txbr
  class CampaignHandler
    attr_reader :project

    def initialize(project)
      @project = project
    end

    def each_resource(&block)
      return to_enum(__method__) unless block_given?
      each_campaign { |campaign| campaign.each_resource(&block) }
    end

    def each_campaign
      return to_enum(__method__) unless block_given?

      project.braze_api.campaigns.each do |campaign_data|
        yield Campaign.new(project, campaign_data)
      end
    end

    alias_method :each_item, :each_campaign
  end
end
