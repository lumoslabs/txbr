require 'liquid'

module Txbr
  class Campaign
    ITEM_TYPE = 'campaign'.freeze
    TEMPLATE_KEYS = %w(body subject preheader message alert).freeze

    attr_reader :project, :campaign_id

    def initialize(project, campaign_data)
      @project = project
      @campaign_data = campaign_data
      @campaign_id = campaign_data['id']
    end

    def each_resource(&block)
      return to_enum(__method__) unless block_given?
      template_group.each_resource(&block)
    end

    def metadata
      @metadata ||= {
        item_type: ITEM_TYPE,
        campaign_name: campaign_name,
        campaign_id: campaign_id,
        last_edited: last_edited
      }
    rescue => e
      {}
    end

    def prerender_variables
      @prerender_variables ||= {
        'campaign.${api_id}' => campaign_id
      }
    end

    private

    attr_reader :campaign_data

    def last_edited
      campaign_data['last_edited']
    end

    def template_group
      @template_group ||= TemplateGroup.new(campaign_name, templates, project)
    end

    def templates
      details['messages'].flat_map do |message_id, props|
        TEMPLATE_KEYS.each_with_object([]) do |key, ret|
          begin
            if message = props[key]
              ret << Txbr::Template.new(
                message_id, message, prerender_variables
              )
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
