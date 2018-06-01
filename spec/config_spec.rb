require 'spec_helper'
require 'tempfile'
require 'yaml'

require 'support/test_config'

describe Txbr::Config do
  before(:each) do
    # clear out config before each test
    Txbr::Config.instance_variable_set(:@raw_config, nil)
  end

  let(:config) { TestConfig.config }

  shared_examples 'a successful configuration' do
    it 'is configured correctly' do
      expect(Txbr::Config.projects.size).to eq(1)
      project = Txbr::Config.projects.first

      expect(project.handler_id).to eq('email-templates')
      expect(project.braze_api_key).to eq('braze_api_key')
      expect(project.braze_api_url).to eq('https://somewhere.braze.com')
      expect(project.transifex_api_username).to eq('transifex_username')
      expect(project.transifex_api_password).to eq('transifex_password')
      expect(project.strings_format).to eq('YML')
      expect(project.source_lang).to eq('en')

      # @TODO: remove once Braze implements the endpoints we asked for
      expect(project.braze_email_address).to eq('braze@email.com')
      expect(project.braze_password).to eq('braze_password')
      expect(project.braze_app_group_id).to eq('5551212')
    end
  end

  describe '.projects' do
    context 'when config is specified as a string' do
      around do |example|
        with_env('TXBR_CONFIG' => "raw://#{YAML.dump(config)}") do
          example.run
        end
      end

      it_behaves_like 'a successful configuration'
    end

    context 'when config is specified as a file' do
      let(:file) do
        Tempfile.new('config').tap do |file|
          file.write(YAML.dump(config))
          file.flush
        end
      end

      around do |example|
        with_env('TXBR_CONFIG' => "file://#{file.path}") do
          example.run
        end
      end

      after do
        file.close
        file.unlink
      end

      it_behaves_like 'a successful configuration'
    end
  end
end
