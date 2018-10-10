$:.push(File.dirname(__FILE__))

require 'rspec'
require 'rack/test'
require 'pry-byebug'
require 'txbr'
require 'txgh'
require 'cgi'

require 'support/env_helpers'

RSpec.configure do |config|
  config.include(EnvHelpers)
end
