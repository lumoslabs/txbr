$:.push(File.dirname(__FILE__))

require 'rspec'
require 'pry-byebug'
require 'txbr'
require 'cgi'
require 'vcr'

require 'support/env_helpers'

FAKE_SESSION_ID = '123abc123abc123abc123abc123abc12'

VCR.configure do |config|
  config.cassette_library_dir = 'spec/fixtures/cassettes'
  config.hook_into :webmock

  %w(BRAZE_EMAIL_ADDRESS BRAZE_PASSWORD).each do |var|
    config.filter_sensitive_data(var) { ENV[var] || var }
    config.filter_sensitive_data(var) { CGI.escape(ENV[var] || var) }
  end

  config.before_record do |interaction|
    # Clear out the body for requests to the dashboard, etc. We need to keep
    # the body for the auth request so mechanize can find the login form.
    if %w(/auth).none? { |str| interaction.request.uri.include?(str) }
      interaction.response.body.replace('')
      interaction.response.headers['Content-Length'] = ['0']
    end

    # remove session ID from request cookie header
    interaction.request.headers.fetch('Cookie', []).each do |header|
      header.sub!(/_session_id=[a-z0-9]{32}/, "_session_id=#{FAKE_SESSION_ID}")
    end

    # remove session ID from response set cookie headers
    interaction.response.headers.fetch('Set-Cookie', []).each do |header|
      header.sub!(/_session_id=[a-z0-9]{32}/, "_session_id=#{FAKE_SESSION_ID}")
    end
  end
end

RSpec.configure do |config|
  config.include(EnvHelpers)
end
