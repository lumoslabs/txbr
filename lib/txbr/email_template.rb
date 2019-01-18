require 'liquid'

module Txbr
  class EmailTemplate
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
      %w(body subject preheader).map do |name|
        Txbr::Template.new(email_template_id, ::Liquid::Template.parse(details[name]))
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
