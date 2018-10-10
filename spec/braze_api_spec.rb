require 'spec_helper'
require 'support/fake_connection'

describe Txbr::BrazeApi do
  let(:api_key) { 'abc123' }
  let(:api_url) { 'https://somewhere.braze.com' }
  let(:connection) { FakeConnection.new(interactions) }
  let(:client) { described_class.new(api_key, api_url, connection: connection) }

  shared_examples 'a client request that handles errors' do
    context 'when the resource is not found' do
      let(:interactions) do
        super().tap do |inter|
          inter[0][:response][:status] = 404
        end
      end

      it 'raises a not found error' do
        expect { subject }.to raise_error(Txbr::BrazeNotFoundError)
      end
    end

    context 'when the request is unauthorized' do
      let(:interactions) do
        super().tap do |inter|
          inter.unshift(
            request: inter[0][:request],
            response: { status: 401 }
          )
        end
      end

      it 'raises an unauthorized error' do
        expect { subject }.to raise_error(Txbr::BrazeUnauthorizedError)
      end
    end

    context 'when some other bad thing happens' do
      let(:interactions) do
        super().tap do |inter|
          inter[0][:response][:status] = 500
        end
      end

      it 'raises a generic error' do
        expect { subject }.to raise_error(Txbr::BrazeApiError)
      end
    end
  end

  describe '#each_email_template' do
    subject { client.each_email_template.to_a }

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

  describe '#get_email_template_details' do
    subject { client.get_email_template_details(email_template_id: email_template_id) }
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
        request: { verb: 'get', url: described_class::TEMPLATE_INFO_PATH, params: { email_template_id: email_template_id } },
        response: { status: 200, body: details.to_json }
      }]
    end

    it 'retrieves the template details' do
      expect(subject).to eq(details)
    end

    it_behaves_like 'a client request that handles errors'
  end
end
