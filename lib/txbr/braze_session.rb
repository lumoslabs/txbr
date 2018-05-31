require 'cgi'
require 'mechanize'

module Txbr
  class BrazeSession
    attr_reader :api_url, :email_address, :password

    def initialize(api_url, email_address, password)
      @api_url = api_url
      @email_address = email_address
      @password = password

      reset!
    end

    def session_id
      @session_id ||= begin
        agent = Mechanize.new
        url = Txbr::Utils.url_join(api_url, "auth?email=#{CGI.escape(email_address)}")

        agent.get(url) do |page|
          page.form_with(id: 'developer_signin').tap do |form|
            form['developer[password]'] = password
            form.submit
          end
        end

        agent
          .cookies
          .find { |cookie| cookie.name == '_session_id' }
          .value
      end
    end

    def reset!
      @session_id = nil
    end
  end
end
