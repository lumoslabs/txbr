require 'spec_helper'
require 'support/standard_setup'
require 'json'

describe Txbr::Campaign do
  include_context 'standard setup'

  let(:campaign_id) { 'abc123' }
  let(:campaign) { described_class.new(project, campaign_id) }

  let(:first_message) do
    <<~MESSAGE
        {% assign project_slug = "my_project" %}
        {% assign resource_slug = "my_resource" %}
        {% assign translation_enabled = true %}
        {% connected_content http://my_strings_api.com?project_slug={{project_slug}}&resource_slug={{resource_slug}} :save strings %}
        {% connected_content http://my_strings_api.com?project_slug=my_project&resource_slug=my_resource :save footer %}

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
      {% assign resource_slug = "my_resource" %}
      {% assign translation_enabled = true %}
      {% connected_content http://my_strings_api.com?project_slug={{project_slug}}&resource_slug={{resource_slug}} :save strings %}
      {{strings.meta.subject_line | default: 'You lucky duck maybe'}}
    HTML
  end

  describe '#each_resource' do
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

    it 'extracts and groups all strings with the same project, resource, and prefix' do
      resource = campaign.each_resource.to_a.first
      expect(resource.tx_resource.project_slug).to eq('my_project')
      expect(resource.tx_resource.resource_slug).to eq('my_resource-strings')

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
      expect(tx_resource.resource_slug).to eq('my_resource-strings')
      expect(tx_resource.source_file).to eq('World Domination')
      expect(tx_resource.source_lang).to eq(project.source_lang)
      expect(tx_resource.type).to eq(project.strings_format)
    end

    it 'constructs a separate resource for the footer' do
      footer = campaign.each_resource.to_a.last
      expect(footer.tx_resource.project_slug).to eq('my_project')
      expect(footer.tx_resource.resource_slug).to eq('my_resource-footer')

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
      let(:first_message) do
        super().tap do |subj|
          subj.sub!(
            'resource_slug = "my_resource"',
            'resource_slug = "my_other_resource"'
          )
        end
      end

      it 'includes the additional resource' do
        resources = campaign.each_resource.to_a
        expect(resources.size).to eq(3)

        expect(resources.first.phrases).to_not(
          include({ 'key' => 'meta.subject_line', 'string' => 'You lucky duck maybe' })
        )

        expect(resources.last.phrases).to eq(
          [{ 'key' => 'meta.subject_line', 'string' => 'You lucky duck maybe' }]
        )

        expect(resources.first.tx_resource.project_slug).to eq('my_project')
        expect(resources.first.tx_resource.resource_slug).to eq('my_other_resource-strings')
      end
    end
  end
end
