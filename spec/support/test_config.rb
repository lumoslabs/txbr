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
      }]
    }
  end
end
