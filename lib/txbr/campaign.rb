require 'liquid'

module Txbr
  class Campaign
    attr_reader :project, :campaign_id

    def initialize(project, campaign_id)
      @project = project
      @campaign_id = campaign_id
    end

    def each_resource(&block)
      return to_enum(__method__) unless block_given?
      template_group.each_resource(&block)
    end

    private

    def template_group
      @template_group ||= TemplateGroup.new(campaign_name, templates, project)
    end

    def templates
      details['messages'].map do |message_id, props|
        Txbr::Template.new(message_id, ::Liquid::Template.parse(props['message']))
      end
    end

    def campaign_name
      details['name']
    end

    def details
      @details ||= project.braze_api.campaigns.details(
        campaign_id: campaign_id
      )
    end
  end
end
