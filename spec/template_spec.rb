require 'spec_helper'

describe Txbr::Template do
  subject { described_class.new(id, source, prerender_variables) }

  let(:prerender_variables) { {} }
  let(:id) { 'foobar' }
  let(:source) do
    <<~SRC
      <h1>Braze campaign is {{campaign.${api_id}}}</h1>
      <h2>Hello, {{${first_name}}}</h2>
      <h3>I speak {{custom_attributes.${preferred_language} | default: 'en'}}</h3>
      <h3>{{'foo bar ' | append: custom_attributes.${foobar}}}</h3>
    SRC
  end

  context 'with a direct variable replacement' do
    let(:prerender_variables) do
      {
        'campaign.${api_id}' => 'abc123',
        '${first_name}' => 'Dwight',
        'custom_attributes.${foobar}' => 'baz'
      }
    end

    it 'prerenders correctly' do
      expect(subject.render).to eq(<<~TEXT)
        <h1>Braze campaign is abc123</h1>
        <h2>Hello, Dwight</h2>
        <h3>I speak en</h3>
        <h3>foo bar baz</h3>
      TEXT
    end
  end

  context 'with no variable replacements' do
    it 'renders without erroring' do
      expect(subject.render).to eq(<<~TEXT)
        <h1>Braze campaign is </h1>
        <h2>Hello, </h2>
        <h3>I speak en</h3>
        <h3>foo bar </h3>
      TEXT
    end
  end
end
