require 'spec_helper'

describe Txbr::BrazeSession do
  # we need to hard-code this in order for VCR to successfully match requests
  # after the initial recording
  let(:api_url) { 'https://dashboard-03.braze.com' }

  # NOTE: you will need to provide these env variables if you want to
  # re-generate the VCR cassettes that depend on Braze login.
  let(:email_address) { ENV['BRAZE_EMAIL_ADDRESS'] || 'BRAZE_EMAIL_ADDRESS' }
  let(:password) { ENV['BRAZE_PASSWORD'] || 'BRAZE_PASSWORD' }

  let(:session) { described_class.new(api_url, email_address, password) }

  describe '#session_id' do
    around do |example|
      VCR.use_cassette('braze_login') { example.run }
    end

    it 'logs in and is issued a session id' do
      expect(session.session_id).to match(/[a-z0-9]{32}/)
    end

    it 'does not create a new session if called more than once' do
      # expect mechanize to be invoked exactly once
      expect(Mechanize).to receive(:new).and_call_original.once

      # grab the session ID multiple times, which should invoke
      # mechanize the first time only
      session.session_id
      session.session_id
    end
  end

  describe '#reset!' do
    it 'causes a new session to be requested' do
      # mechanize should be invoked twice, once before the session is reset
      # and once after
      expect(Mechanize).to receive(:new).and_call_original.twice

      # we have to wrap the session_id calls in separate use_cassette calls
      # because VCR isn't smart enough to stub the requests more than once
      # (it would be great if cassettes had a "rewind" option, but alas)
      VCR.use_cassette('braze_login') { session.session_id }
      session.reset!
      VCR.use_cassette('braze_login') { session.session_id }
    end
  end
end
