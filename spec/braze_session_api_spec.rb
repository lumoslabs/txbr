require 'spec_helper'
require 'support/fake_braze_session'
require 'support/fake_connection'

describe Txbr::BrazeSessionApi do
  let(:session_id) { 'session_id' }
  let(:app_group_id) { 'app_group_id' }
  let(:api_url) { 'https://somewhere.braze.com' }
  let(:session) { FakeBrazeSession.new(api_url, session_id) }
  let(:connection) { FakeConnection.new(interactions) }
  let(:client) { described_class.new(session, app_group_id, connection: connection) }

  shared_examples 'a client request that handles errors' do
    context 'when the resource is not found' do
      let(:interactions) do
        super().tap do |inter|
          inter[0][:response][:status] = 404
        end
      end

      it 'raises an error' do
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

      it 'resets the session and tries again' do
        expect { subject }.to_not raise_error
        expect(session).to be_reset
      end
    end

    context 'when some other bad thing happens' do
      let(:interactions) do
        super().tap do |inter|
          inter[0][:response][:status] = 500
        end
      end

      it 'raises an error' do
        expect { subject }.to raise_error(Txbr::BrazeApiError)
      end
    end
  end

  describe '#each_email_template' do
    before do
      stub_const("#{described_class.name}::EMAIL_TEMPLATE_BATCH_SIZE", 1)
    end

    subject { client.each_email_template.to_a }

    let(:interactions) do
      [{
        request: { verb: 'get', url: 'engagement/email_templates', start: 0, length: 1 },
        response: { status: 200, body: { results: [{ id: '123abc' }] }.to_json }
      }, {
        request: { verb: 'get', url: 'engagement/email_templates', start: 1, length: 1 },
        response: { status: 200, body: { results: [{ id: '456def' }] }.to_json }
      }, {
        request: { verb: 'get', url: 'engagement/email_templates', start: 2, length: 0 },
        response: { status: 200, body: { results: [] }.to_json }
      }]
    end

    it 'yields each template' do
      expect(subject).to eq([{ 'id' => '123abc' }, { 'id' => '456def' }])
    end

    it_behaves_like 'a client request that handles errors'
  end

  describe '#get_email_template_details' do
    subject { client.get_email_template_details(email_template_id: email_template_id) }
    let(:email_template_id) { 'abc123' }

    let(:details) do
      {
        'name' => 'Foo Template',
        'template' => "<html><body>I'm a little teapot</body</html>",
        'subject' => 'Subject subject',
        'preheader' => 'Preheader preheader',
      }
    end

    let(:interactions) do
      [{
        request: { verb: 'get', url: "engagement/email_templates/#{email_template_id}" },
        response: { status: 200, body: details.to_json }
      }]
    end

    it 'retrieves the template details' do
      expect(subject).to eq(details)
    end

    it_behaves_like 'a client request that handles errors'
  end
end
