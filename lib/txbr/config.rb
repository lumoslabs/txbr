require 'yaml'

module Txbr
  class Config
    class << self
      def projects
        @projects ||= raw_config[:projects].map do |conf|
          Project.new(conf)
        end
      end

      private

      def raw_config
        @raw_config ||= begin
          scheme, payload = ENV['TXBR_CONFIG'].split('://')
          send(:"load_#{scheme}", payload)
        end
      end

      def load_file(payload)
        deep_symbolize_keys(YAML.load_file(payload))
      end

      def load_raw(payload)
        deep_symbolize_keys(YAML.load(payload))
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
