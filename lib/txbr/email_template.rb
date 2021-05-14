require 'liquid'
require 'txgh'

module Txbr
  class EmailTemplate
    ITEM_TYPE = 'email_template'.freeze
    TEMPLATE_KEYS = %w(body subject preheader).freeze

    attr_reader :project, :email_template_id

    def initialize(project, tmpl_data)
      @project = project
      @tmpl_data = tmpl_data
      @email_template_id = tmpl_data['email_template_id']
    end

    def each_resource(&block)
      return to_enum(__method__) unless block_given?
      template_group.each_resource(&block)
    end

    def metadata
      @metadata ||= {
        item_type: ITEM_TYPE,
        template_name: template_name,
        template_id: email_template_id,
        last_edited: last_edited
      }
    rescue => e
      {}
    end

    private

    attr_reader :tmpl_data

    def last_edited
      tmpl_data['updated_at']
    end

    def template_group
      @template_group ||= TemplateGroup.new(template_name, templates, project)
    end

    def templates
      TEMPLATE_KEYS.each_with_object([]) do |name, ret|
        begin
          ret << Txbr::Template.new(email_template_id, details[name])
        rescue => e
          Txgh.events.publish_error!(e, metadata.merge(template_key: name))
        end
      end
    end

    def template_name
      details['template_name']
    end

    def details
      @details ||= project.braze_api.email_templates.details(
        email_template_id: email_template_id
      )
    end
  end
end
