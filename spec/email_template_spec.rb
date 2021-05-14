require 'spec_helper'
require 'support/standard_setup'
require 'json'

describe Txbr::EmailTemplate do
  include_context 'standard setup'

  let(:email_template_id) { 'abc123' }
  let(:last_edited) { '2021-03-18T16:20:57+00:00' }
  let(:tmpl_data) { Hash['email_template_id', email_template_id, 'updated_at', last_edited] }
  let(:email_template) { described_class.new(project, tmpl_data) }

  let(:body_html) do
    <<~HTML
      <html>
        <head>
          {% assign project_slug = "my_project" %}
          {% assign resource_slug = "my_resource" %}
          {% assign translation_enabled = true %}
          {% connected_content http://my_strings_api.com?project_slug={{project_slug}}&resource_slug={{resource_slug}} :save strings %}
          {% connected_content http://my_strings_api.com?project_slug=my_project&resource_slug=my_footer_resource :save footer %}
          {% if strings.__http_status_code__ != 200 %}
            {% abort_message("Error fetching translations") %}
          {% endif %}
        </head>
        <body>
          {{strings.header | default: 'Buy our stuff!'}}
          {% if user.gets_discount? %}
            {{strings.discount | default: 'You get a discount'}}
          {% else %}
            {{strings.no_discount | default: 'You get no discount'}}
          {% endif %}
          {{footer.company | default: 'Megamarketing Corp'}}
        </body>
      </html>
    HTML
  end

  let(:subject_html) do
    <<~HTML
      {% assign project_slug = "my_project" %}
      {% assign resource_slug = "my_resource" %}
      {% assign translation_enabled = true %}
      {% connected_content http://my_strings_api.com?project_slug={{project_slug}}&resource_slug={{resource_slug}} :save strings %}
      {{strings.meta.subject_line | default: 'You lucky duck maybe'}}
    HTML
  end

  let(:preheader_html) do
    <<~HTML
      {% assign project_slug = "my_project" %}
      {% assign resource_slug = "my_resource" %}
      {% assign translation_enabled = true %}
      {% connected_content http://my_strings_api.com?project_slug={{project_slug}}&resource_slug={{resource_slug}} :save strings %}
      {{strings.meta.preheader | default: 'Our stuff is the bomb and you should buy it.'}}
    HTML
  end

  let(:braze_interactions) do
    [{
      request: {
        verb: 'get',
        url: Txbr::EmailTemplatesApi::TEMPLATE_DETAILS_PATH,
        params: { email_template_id: email_template_id }
      },
      response: {
        status: 200,
        body: {
          template_name: 'Super Slick Awesome',
          body: body_html,
          subject: subject_html,
          preheader: preheader_html
        }.to_json
      }
    }]
  end

  describe '#each_resource' do
    it 'extracts and groups all strings with the same project, resource, and prefix' do
      resource = email_template.each_resource.to_a.first
      expect(resource.tx_resource.project_slug).to eq('my_project')
      expect(resource.tx_resource.resource_slug).to eq('my_resource')

      # notice how it combined strings from the subject, preheader,
      # and template (i.e. HTML body)
      expect(resource.phrases).to eq([
        { 'key' => 'header', 'string' => 'Buy our stuff!' },
        { 'key' => 'discount', 'string' => 'You get a discount' },
        { 'key' => 'no_discount', 'string' => 'You get no discount' },
        { 'key' => 'meta.subject_line', 'string' => 'You lucky duck maybe' },
        { 'key' => 'meta.preheader', 'string' => 'Our stuff is the bomb and you should buy it.' }
      ])
    end

    it 'constructs a txgh resource' do
      resource = email_template.each_resource.to_a.first
      tx_resource = resource.tx_resource

      expect(tx_resource.project_slug).to eq('my_project')
      expect(tx_resource.resource_slug).to eq('my_resource')
      expect(tx_resource.source_file).to eq('Super Slick Awesome')
      expect(tx_resource.source_lang).to eq(project.source_lang)
      expect(tx_resource.type).to eq(project.strings_format)
    end

    it 'constructs a separate resource for the footer' do
      footer = email_template.each_resource.to_a.last
      expect(footer.tx_resource.project_slug).to eq('my_project')
      expect(footer.tx_resource.resource_slug).to eq('my_footer_resource')

      expect(footer.phrases).to eq([
        { 'key' => 'company', 'string' => 'Megamarketing Corp' }
      ])
    end

    context 'with translations disabled for the subject' do
      let(:subject_html) do
        super().tap do |subj|
          subj.sub!('translation_enabled = true', 'translation_enabled = false')
        end
      end

      it 'does not include translations for the subject line' do
        expect(email_template.each_resource.to_a.first.phrases).to_not(
          include({ 'key' => 'meta.subject_line', 'string' => 'You lucky duck maybe' })
        )
      end
    end

    context 'when the subject comes from a separate resource' do
      let(:subject_html) do
        super().tap do |subj|
          subj.sub!(
            'resource_slug = "my_resource"',
            'resource_slug = "my_other_resource"'
          )
        end
      end

      it 'includes the additional resource' do
        resources = email_template.each_resource.to_a
        expect(resources.size).to eq(3)

        expect(resources.first.phrases).to_not(
          include({ 'key' => 'meta.subject_line', 'string' => 'You lucky duck maybe' })
        )

        expect(resources.last.phrases).to eq(
          [{ 'key' => 'meta.subject_line', 'string' => 'You lucky duck maybe' }]
        )

        expect(resources.last.tx_resource.project_slug).to eq('my_project')
        expect(resources.last.tx_resource.resource_slug).to eq('my_other_resource')
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

        expect { email_template.each_resource.to_a }.to change { errors.size }.by_at_least(1)

        email_template.class::TEMPLATE_KEYS.each do |key|
          idx = errors.index { |(_err, params)| params[:template_key] == key }
          expect(errors[idx][1]).to eq(email_template.metadata.merge(template_key: key))
          errors.delete_at(idx)
        end

        expect(errors).to be_empty
      end
    end
  end

  describe '#metadata' do
    it 'includes the correct values' do
      expect(email_template.metadata).to eq(
        item_type: 'email_template',
        template_name: 'Super Slick Awesome',
        template_id: email_template_id,
        last_edited: last_edited
      )
    end
  end
end
