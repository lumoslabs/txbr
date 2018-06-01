require 'txgh'
require 'support/fake_braze_session'
require 'support/fake_connection'
require 'support/test_config'

shared_context 'standard setup' do
  let(:session_id) { 'session_id' }
  let(:app_group_id) { config[:braze_app_group_id] }
  let(:braze_connection) { FakeConnection.new(braze_interactions) }
  let(:transifex_connection) { FakeConnection.new(transifex_interactions) }
  let(:braze_session) { FakeBrazeSession.new(config[:braze_api_url], session_id) }
  let(:braze_api) { Txbr::BrazeSessionApi.new(braze_session, app_group_id, connection: braze_connection) }
  let(:transifex_api) { Txgh::TransifexApi.create_from_connection(transifex_connection) }
  let(:config) { TestConfig.config[:projects].first }
  let(:project) { Txbr::Project.new(config.merge(braze_api: braze_api, transifex_api: transifex_api)) }

  # override these
  let(:braze_interactions) { [] }
  let(:transifex_interactions) { [] }
end
