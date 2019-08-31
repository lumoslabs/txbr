require 'liquid'
require 'txgh'

module Txbr
  class EmailTemplate
    TEMPLATE_KEYS = %w(body subject preheader).freeze

    attr_reader :project, :email_template_id

    def initialize(project, email_template_id)
      @project = project
      @email_template_id = email_template_id
    end

    def each_resource(&block)
      return to_enum(__method__) unless block_given?
      template_group.each_resource(&block)
    end

    private

    def template_group
      @template_group ||= TemplateGroup.new(template_name, templates, project)
    end

    def templates
      TEMPLATE_KEYS.each_with_object([]) do |name, ret|
        begin
          liquid_tmpl = ::Liquid::Template.parse(details[name])
          ret << Txbr::Template.new(email_template_id, liquid_tmpl)
        rescue ::Liquid::SyntaxError => e
          Txgh.events.publish_error!(e)
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
