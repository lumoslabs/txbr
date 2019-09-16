require 'liquid'

module Txbr
  class Campaign
    ITEM_TYPE = 'campaign'.freeze
    TEMPLATE_KEYS = %w(body subject preheader message alert).freeze

    attr_reader :project, :campaign_id

    def initialize(project, campaign_id)
      @project = project
      @campaign_id = campaign_id
    end

    def each_resource(&block)
      return to_enum(__method__) unless block_given?
      template_group.each_resource(&block)
    end

    def metadata
      @metadata ||= {
        item_type: ITEM_TYPE,
        campaign_name: campaign_name,
        campaign_id: campaign_id
      }
    rescue => e
      {}
    end

    private

    def template_group
      @template_group ||= TemplateGroup.new(campaign_name, templates, project)
    end

    def templates
      details['messages'].flat_map do |message_id, props|
        TEMPLATE_KEYS.each_with_object([]) do |key, ret|
          begin
            if message = props[key]
              ret << Txbr::Template.new(message_id, ::Liquid::Template.parse(message))
            end
          rescue => e
            Txgh.events.publish_error!(e, metadata.merge(template_key: key))
          end
        end
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
