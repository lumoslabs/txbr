$:.unshift File.join(File.dirname(__FILE__), 'lib')
require 'txbr/version'

Gem::Specification.new do |s|
  s.name     = 'txbr'
  s.version  = ::Txbr::VERSION
  s.authors  = ['Cameron Dutro']
  s.email    = ['camertron@gmail.com']
  s.homepage = 'https://github.com/lumoslabs/txbr'

  s.description = s.summary = 'A library for syncing translation resources between Braze and Transifex.'

  s.platform = Gem::Platform::RUBY
  s.has_rdoc = true

  s.add_dependency 'abroad', '~> 4.5'
  s.add_dependency 'faraday', '~> 0.9'
  s.add_dependency 'faraday_middleware', '~> 0.10'
  s.add_dependency 'liquid', '~> 4.0'
  s.add_dependency 'mechanize', '~> 2.7'
  s.add_dependency 'sinatra', '~> 2.0'
  s.add_dependency 'sinatra-contrib', '~> 2.0'
  s.add_dependency 'txgh', '~> 6.6'

  s.require_path = 'lib'
  s.files = Dir['{lib,spec}/**/*', 'README.md', 'txbr.gemspec', 'LICENSE']
end
