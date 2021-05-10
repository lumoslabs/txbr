require 'spec_helper'
require 'support/standard_setup'
require 'json'

describe Txbr::Campaign do
  include_context 'standard setup'

  let(:campaign_id) { 'abc123' }
  let(:last_edited) { '2021-03-18T16:20:57+00:00' }
  let(:campaign_data) { Hash['id', campaign_id, 'last_edited', last_edited] }
  let(:campaign) { described_class.new(project, campaign_data) }

  let(:first_message) do
    <<~MESSAGE
      {% assign project_slug = "my_project" %}
      {% assign translation_enabled = true %}
      {% connected_content http://my_strings_api.com?project_slug={{project_slug}}&resource_slug={{campaign.${api_id}}} :save strings %}
      {% connected_content http://my_strings_api.com?project_slug=my_project&resource_slug=my_footer_resource :save footer %}

      {{strings.header | default: 'Buy our stuff!'}}
      {% if user.gets_discount? %}
        {{strings.discount | default: 'You get a discount'}}
      {% else %}
        {{strings.no_discount | default: 'You get no discount'}}
      {% endif %}
      {{footer.company | default: 'Megamarketing Corp'}}
    MESSAGE
  end

  let(:second_message) do
    <<~HTML
      {% assign project_slug = "my_project" %}
      {% assign translation_enabled = true %}
      {% connected_content http://my_strings_api.com?project_slug={{project_slug}}&resource_slug={{campaign.${api_id}}} :save strings %}
      {{strings.meta.subject_line | default: 'You lucky duck maybe'}}
    HTML
  end

  let(:braze_interactions) do
    [{
      request: {
        verb: 'get',
        url: Txbr::CampaignsApi::CAMPAIGN_DETAILS_PATH,
        params: { campaign_id: campaign_id }
      },
      response: {
        status: 200,
        body: {
          name: 'World Domination',
          messages: {
            abc123: { name: 'Subliminal Messaging', message: first_message },
            def456: { name: 'Propaganda', message: second_message }
          }
        }.to_json
      }
    }]
  end

  describe '#each_resource' do
    it 'extracts and groups all strings with the same project, resource, and prefix' do
      resource = campaign.each_resource.to_a.first
      expect(resource.tx_resource.project_slug).to eq('my_project')
      expect(resource.tx_resource.resource_slug).to eq(campaign_id)

      # notice how it combined strings from both messages,
      expect(resource.phrases).to eq([
        { 'key' => 'header', 'string' => 'Buy our stuff!' },
        { 'key' => 'discount', 'string' => 'You get a discount' },
        { 'key' => 'no_discount', 'string' => 'You get no discount' },
        { 'key' => 'meta.subject_line', 'string' => 'You lucky duck maybe' }
      ])
    end

    it 'constructs a txgh resource' do
      resource = campaign.each_resource.to_a.first
      tx_resource = resource.tx_resource

      expect(tx_resource.project_slug).to eq('my_project')
      expect(tx_resource.resource_slug).to eq(campaign_id)
      expect(tx_resource.source_file).to eq('World Domination')
      expect(tx_resource.source_lang).to eq(project.source_lang)
      expect(tx_resource.type).to eq(project.strings_format)
    end

    it 'constructs a separate resource for the footer' do
      footer = campaign.each_resource.to_a.last
      expect(footer.tx_resource.project_slug).to eq('my_project')
      expect(footer.tx_resource.resource_slug).to eq('my_footer_resource')

      expect(footer.phrases).to eq([
        { 'key' => 'company', 'string' => 'Megamarketing Corp' }
      ])
    end

    context 'with translations disabled for the first message' do
      let(:first_message) do
        super().tap do |subj|
          subj.sub!('translation_enabled = true', 'translation_enabled = false')
        end
      end

      it 'does not include translations for the first message' do
        expect(campaign.each_resource.to_a.first.phrases).to_not(
          include({ 'key' => 'header', 'string' => 'Buy our stuff!' })
        )
      end
    end

    context 'when the message comes from a separate resource' do
      it 'includes the additional resource' do
        resources = campaign.each_resource.to_a
        expect(resources.size).to eq(2)

        expect(resources.first.phrases).to_not(
          include({ 'key' => 'company', 'string' => 'Megamarketing Corp' })
        )

        expect(resources.last.phrases).to(
          include({ 'key' => 'company', 'string' => 'Megamarketing Corp' })
        )

        first = resources.first.tx_resource
        second = resources.last.tx_resource

        expect(first.project_slug).to eq('my_project')
        expect(first.resource_slug).to eq(campaign_id)

        expect(second.project_slug).to eq('my_project')
        expect(second.resource_slug).to eq('my_footer_resource')
      end
    end

    context 'when an error occurs' do
      before do
        allow(::Liquid::Template).to receive(:parse).and_raise('jelly beans')
      end

      it 'passes item metadata to the error handler' do
        errors = []

        Txgh.events.subscribe('errors') do |e, params|
          errors << [e, params]
        end

        expect { campaign.each_resource.to_a }.to change { errors.size }.by_at_least(1)

        errors.each do |(_error, params)|
          expect(params).to eq(campaign.metadata.merge(template_key: 'message'))
        end
      end
    end
  end

  describe '#metadata' do
    it 'includes the correct values' do
      expect(campaign.metadata).to eq(
        item_type: 'campaign',
        campaign_name: 'World Domination',
        campaign_id: campaign_id,
        last_edited: last_edited
      )
    end
  end
end
