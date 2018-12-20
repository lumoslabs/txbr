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
      details['messages'].map do |_message_id, props|
        Txbr::Template.new(::Liquid::Template.parse(props['message']))
      end
    end

    def campaign_name
      details['name']
    end

    def details
      @details ||= project.braze_api.campaigns.details(
        campaign_id: campaign_id
      ).tap do |deets|  # TODO: remove
        deets['messages'].each_pair do |_, props|
          props['message'] = <<~END
            <html>
              <head>
                {% assign project_slug = "my_transifex_project" %}
                {% assign resource_slug = "my_transifex_resource" %}
                {% connected_content http://txgh.lumoslabs.com/api/strings.json?project_slug={{project_slug}}&resource_slug={{resource_slug}}&locale={{${language} | default: 'en'}}&strings_format=YML :basic_auth txgh :save strings :retry %}
              </head>
              <body>
                {{strings.header.title | default: "Buy my stuff!"}}
              </body>
            </html>
          END
        end
      end
    end
  end
end
