require 'txgh'
require 'support/fake_connection'
require 'support/test_config'

shared_context 'standard setup' do
  let(:config) { TestConfig.config[:projects].first }
  let(:api_url) { config[:braze_api_url] }
  let(:api_key) { config[:braze_api_key] }
  let(:braze_connection) { FakeConnection.new(braze_interactions) }
  let(:transifex_connection) { FakeConnection.new(transifex_interactions) }
  let(:braze_api) { Txbr::BrazeApi.new(api_key, api_url, connection: braze_connection) }
  let(:transifex_api) { Txgh::TransifexApi.create_from_connection(transifex_connection) }
  let(:project) { Txbr::Project.new(config.merge(braze_api: braze_api, transifex_api: transifex_api)) }

  # override these
  let(:braze_interactions) { [] }
  let(:transifex_interactions) { [] }
end
