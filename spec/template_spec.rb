require 'spec_helper'

describe Txbr::Template do
  subject { described_class.new(id, source, prerender_variables) }

  let(:prerender_variables) { {} }
  let(:id) { 'foobar' }
  let(:source) do
    <<~SRC
      <h1>Braze campaign is {{campaign.${api_id}}}</h1>
    SRC
  end

  context 'with a direct variable replacement' do
    let(:prerender_variables) { { 'campaign.${api_id}' => 'abc123' } }

    it 'prerenders correctly' do
      expect(subject.render.strip).to eq("<h1>Braze campaign is abc123</h1>")
    end
  end

  context 'with no variable replacements' do
    it 'renders without erroring' do
      expect { subject.render }.to_not raise_error
    end
  end
end
