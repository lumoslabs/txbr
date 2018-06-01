$:.unshift(File.dirname(__FILE__))
$:.unshift(File.join(File.dirname(__FILE__), 'lib'))

require 'txbr'
require 'sinatra'

map '/' do
  use Txbr::Application
  run Sinatra::Base
end
