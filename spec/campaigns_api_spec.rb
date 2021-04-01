require 'spec_helper'
require 'support/fake_connection'
require 'shared_examples/api_errors'

require 'json'

describe Txbr::CampaignsApi do
  let(:api_key) { 'abc123' }
  let(:api_url) { 'https://somewhere.braze.com' }
  let(:connection) { FakeConnection.new(interactions) }
  let(:braze_api) { Txbr::BrazeApi.new(api_key, api_url, connection: connection) }
  let(:client) { described_class.new(braze_api) }

  describe '#each' do
    subject { client.each.to_a }

    before do
      stub_const("#{described_class.name}::CAMPAIGN_BATCH_SIZE", 1)
    end

    let(:interactions) do
      [{
        request: { verb: 'get', url: described_class::CAMPAIGN_LIST_PATH, params: { page: 0, include_archived: false } },
        response: { status: 200, body: { campaigns: [{ id: '123abc' }] }.to_json }
      }, {
        request: { verb: 'get', url: described_class::CAMPAIGN_LIST_PATH, params: { page: 1, include_archived: false } },
        response: { status: 200, body: { campaigns: [{ id: '456def' }] }.to_json }
      }, {
        request: { verb: 'get', url: described_class::CAMPAIGN_LIST_PATH, params: { page: 2, include_archived: false } },
        response: { status: 200, body: { campaigns: [] }.to_json }
      }]
    end

    it 'yields each template' do
      expect(subject).to eq([
        { 'id' => '123abc' }, { 'id' => '456def' }
      ])
    end

    it_behaves_like 'a client request that handles errors'
  end

  describe '#details' do
    subject { client.details(campaign_id: campaign_id) }
    let(:campaign_id) { 'abc123' }

    let(:details) do
      {
        'name' => 'World Domination',
        'messages' => [{
          'message' => 'Today vegetables. Tomorrow the world.'
        }, {
          'message' => 'I haz teh power.'
        }]
      }
    end

    let(:interactions) do
      [{
        request: { verb: 'get', url: described_class::CAMPAIGN_DETAILS_PATH, params: { campaign_id: campaign_id } },
        response: { status: 200, body: details.to_json }
      }]
    end

    it 'retrieves the template details' do
      expect(subject).to eq(details)
    end

    it_behaves_like 'a client request that handles errors'
  end
end
