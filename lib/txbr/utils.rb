module Txbr
  module Utils
    def url_join(*segments)
      segments.map { |s| s.sub(/\A\/|\/\z/, '') }.join('/')
    end
  end

  Utils.extend(Utils)
end
