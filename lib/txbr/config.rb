require 'erb'
require 'yaml'

module Txbr
  class Config
    class << self
      def projects
        @projects ||= raw_config[:projects].map do |conf|
          Project.new(conf)
        end
      end

      def transifex_api_username
        raw_config[:transifex_api_username]
      end

      def transifex_api_password
        raw_config[:transifex_api_password]
      end

      private

      def raw_config
        @raw_config ||= begin
          scheme_end_idx = ENV['TXBR_CONFIG'].index('://')
          scheme = ENV['TXBR_CONFIG'][0...scheme_end_idx]
          payload = ENV['TXBR_CONFIG'][(scheme_end_idx + 3)..-1]
          send(:"load_#{scheme}", payload)
        end
      end

      def load_file(payload)
        deep_symbolize_keys(parse(File.read(payload)))
      end

      def load_raw(payload)
        deep_symbolize_keys(parse(payload))
      end

      def parse(str)
        YAML.load(ERB.new(str).result(binding))
      end

      def deep_symbolize_keys(obj)
        case obj
          when Hash
            obj.each_with_object({}) do |(k, v), ret|
              ret[k.to_sym] = deep_symbolize_keys(v)
            end

          when Array
            obj.map do |elem|
              deep_symbolize_keys(elem)
            end

          else
            obj
        end
      end
    end
  end
end
