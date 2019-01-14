require 'liquid'

module Txbr
  autoload :Application,            'txbr/application'
  autoload :BrazeApi,               'txbr/braze_api'
  autoload :Campaign,               'txbr/campaign'
  autoload :CampaignHandler,        'txbr/campaign_handler'
  autoload :CampaignsApi,           'txbr/campaigns_api'
  autoload :ContentTag,             'txbr/content_tag'
  autoload :Commands,               'txbr/commands'
  autoload :Config,                 'txbr/config'
  autoload :EmailTemplate,          'txbr/email_template'
  autoload :EmailTemplateComponent, 'txbr/email_template_component'
  autoload :EmailTemplateHandler,   'txbr/email_template_handler'
  autoload :EmailTemplatesApi,      'txbr/email_templates_api'
  autoload :Liquid,                 'txbr/liquid'
  autoload :Metadata,               'txbr/metadata'
  autoload :Project,                'txbr/project'
  autoload :RequestMethods,         'txbr/request_methods'
  autoload :StringsManifest,        'txbr/strings_manifest'
  autoload :Template,               'txbr/template'
  autoload :TemplateGroup,          'txbr/template_group'
  autoload :Uploader,               'txbr/uploader'
  autoload :Utils,                  'txbr/utils'

  class BrazeApiError < StandardError
    attr_reader :status_code

    def initialize(message, status_code)
      super(message)
      @status_code = status_code
    end
  end

  class BrazeUnauthorizedError < BrazeApiError
    def initialize(message)
      super(message, 401)
    end
  end

  class BrazeNotFoundError < BrazeApiError
    def initialize(message)
      super(message, 404)
    end
  end

  class << self
    def handler_for(project)
      handlers[project.handler_id].new(project)
    end

    def register_handler(id, klass)
      handlers[id] = klass
    end

    private

    def handlers
      @handlers ||= {}
    end
  end

  Txbr.register_handler('email-templates', Txbr::EmailTemplateHandler)
  Txbr.register_handler('campaigns', Txbr::CampaignHandler)

  ::Liquid::Template.register_tag(:connected_content, Txbr::Liquid::ConnectedContentTag)
end
