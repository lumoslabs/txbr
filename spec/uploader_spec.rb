require 'spec_helper'
require 'support/standard_setup'

describe Txbr::Uploader do
  include_context 'standard setup'

  let(:email_template_id) { 'abc123' }

  let(:braze_interactions) do
    [{
      request: {
        verb: 'get',
        url: Txbr::EmailTemplatesApi::TEMPLATE_LIST_PATH,
        params: { offset: 1, limit: Txbr::EmailTemplatesApi::TEMPLATE_BATCH_SIZE }
      },

      response: {
        status: 200,
        body: { templates: [{ email_template_id: email_template_id }] }.to_json
      }
    }, {
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
          subject: '',
          preheader: ''
        }.to_json
      }
    }]
  end

  let(:transifex_interactions) do
    # indicate the resource doesn't exist so the client will create it
    [{
      request: {
        verb: 'get',
        url: "#{Txgh::TransifexApi::API_ROOT}/project/my_project/resource/my_resource-strings/"
      },
      response: { status: 404 }
    }]
  end

  let(:body_html) do
    <<~HTML
      <html>
        <head>
          {% assign project_slug = "my_project" %}
          {% assign resource_slug = "my_resource" %}
          {% assign translation_enabled = true %}
          {% connected_content http://my_strings_api.com?project_slug={{project_slug}}&resource_slug={{resource_slug}} :save strings %}
        </head>
        <body>
          {{strings.header | default: 'Buy our stuff!'}}
          {% if user.gets_discount? %}
            {{strings.discount | default: 'You get a discount'}}
          {% else %}
            {{strings.no_discount | default: 'You get no discount'}}
          {% endif %}
        </body>
      </html>
    HTML
  end

  it 'uploads all resources' do
    # unfortunately this can't be added to the transifex_interactions array
    # because we need to check the upload contents, which is this funky
    # UploadIO object from Faraday
    create_url = "#{Txgh::TransifexApi::API_ROOT}/project/my_project/resources/"

    expect(transifex_connection).to(
      receive(:post)
        .with(create_url, Hash) do |url, body|
          expect(YAML.load(body[:content].io.string)).to eq(
            {
              'en' => {
                'header'=>'Buy our stuff!',
                'discount'=>'You get a discount',
                'no_discount'=>'You get no discount'
              }
            }
          )

          FakeResponse.new(create_url, 200, '', {})
        end
    )

    described_class.new(project).upload_all
  end
end
