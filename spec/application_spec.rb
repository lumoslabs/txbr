require 'spec_helper'

describe '/strings.json' do
  include Rack::Test::Methods

  def app
    Txbr::Application
  end

  let(:api_client) { double(:api_client) }

  let(:strings_format) { 'YML' }
  let(:project_slug) { 'myproject' }
  let(:resource_slug) { 'myresource' }
  let(:locale) { 'en' }

  before do
    allow(Txbr::Config).to(
      receive(:transifex_api_username).and_return('transifex_username')
    )

    allow(Txbr::Config).to(
      receive(:transifex_api_password).and_return('transifex_password')
    )

    allow(Txgh::TransifexApi).to(
      receive(:create_from_credentials).and_return(api_client)
    )
  end

  it 'downloads the resource and returns a JSON version of it' do
    expect(api_client).to(
      receive(:download)
        .with(project_slug, resource_slug, locale)
        .and_return(YAML.dump(locale => { foo: { bar: { baz: 'boo' } } }))
    )

    params = {
      locale: locale,
      project_slug: project_slug,
      resource_slug: resource_slug,
      strings_format: strings_format
    }

    get '/strings.json', params

    expect(last_response).to be_ok
    expect(last_response.body).to eq(
      { foo: { bar: { baz: 'boo' } } }.to_json
    )
  end

  it 'sends back an error response if a param is missing' do
    get '/strings.json'
    expect(last_response.status).to eq(400)
    expect(JSON.parse(last_response.body)).to(
      eq('error' => "Missing parameter 'project_slug'")
    )
  end

  it 'sends back an error response if an unexpected error occurs' do
    expect(api_client).to receive(:download).and_raise('jelly beans')

    params = {
      locale: locale,
      project_slug: project_slug,
      resource_slug: resource_slug,
      strings_format: strings_format
    }

    get '/strings.json', params

    expect(last_response.status).to eq(500)
    expect(JSON.parse(last_response.body)).to(
      eq('error' => 'jelly beans')
    )
  end
end
