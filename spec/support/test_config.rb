class TestConfig
  def self.config
    {
      transifex_api_username: 'transifex_username',
      transifex_api_password: 'transifex_password',
      projects: [{
        handler_id: 'email-templates',
        braze_api_key: 'braze_api_key',
        braze_api_url: 'https://somewhere.braze.com',
        strings_format: 'YML',
        source_lang: 'en',

        # @TODO: remove once Braze implements the endpoints we asked for
        braze_email_address: 'braze@email.com',
        braze_password: 'braze_password',
        braze_app_group_id: '5551212'
      }]
    }
  end
end
