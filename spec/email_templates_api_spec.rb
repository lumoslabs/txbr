require 'spec_helper'
require 'support/fake_connection'
require 'shared_examples/api_errors'

require 'json'

describe Txbr::EmailTemplatesApi do
  let(:api_key) { 'abc123' }
  let(:api_url) { 'https://somewhere.braze.com' }
  let(:connection) { FakeConnection.new(interactions) }
  let(:braze_api) { Txbr::BrazeApi.new(api_key, api_url, connection: connection) }
  let(:client) { described_class.new(braze_api) }

  describe '#each' do
    subject { client.each.to_a }

    before do
      stub_const("#{described_class.name}::TEMPLATE_BATCH_SIZE", 1)
    end

    let(:interactions) do
      [{
        request: { verb: 'get', url: described_class::TEMPLATE_LIST_PATH, params: { offset: 1, limit: 1 } },
        response: { status: 200, body: { templates: [{ email_template_id: '123abc' }] }.to_json }
      }, {
        request: { verb: 'get', url: described_class::TEMPLATE_LIST_PATH, params: { offset: 2, limit: 1 } },
        response: { status: 200, body: { templates: [{ email_template_id: '456def' }] }.to_json }
      }, {
        request: { verb: 'get', url: described_class::TEMPLATE_LIST_PATH, params: { offset: 3, limit: 1 } },
        response: { status: 200, body: { templates: [] }.to_json }
      }]
    end

    it 'yields each template' do
      expect(subject).to eq([
        { 'email_template_id' => '123abc' },
        { 'email_template_id' => '456def' }
      ])
    end

    it_behaves_like 'a client request that handles errors'
  end

  describe '#details' do
    subject { client.details(email_template_id: email_template_id) }
    let(:email_template_id) { 'abc123' }

    let(:details) do
      {
        'template_name' => 'Foo Template',
        'body' => "<html><body>I'm a little teapot</body</html>",
        'subject' => 'Subject subject',
        'preheader' => 'Preheader preheader'
      }
    end

    let(:interactions) do
      [{
        request: { verb: 'get', url: described_class::TEMPLATE_DETAILS_PATH, params: { email_template_id: email_template_id } },
        response: { status: 200, body: details.to_json }
      }]
    end

    it 'retrieves the template details' do
      expect(subject).to eq(details)
    end

    it_behaves_like 'a client request that handles errors'
  end
end
