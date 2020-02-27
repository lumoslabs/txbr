module Txbr
  class Template
    attr_reader :id, :liquid_template

    def initialize(id, source, prerender_variables = {})
      @id = id

      @liquid_template = ::Liquid::Template.parse(
        prerender(source, prerender_variables)
      )
    end

    def each_content_tag
      return to_enum(__method__) unless block_given?

      content_tags.each do |content_tag|
        next unless translation_enabled?
        yield content_tag
      end
    end

    def render
      liquid_template.render
    end

    def root
      liquid_template.root
    end

    private

    def translation_enabled?
      return @translation_enabled unless @translation_enabled.nil?

      liquid_template.root.nodelist.each do |node|
        if node.is_a?(::Liquid::Assign)
          variable = node.instance_variable_get(:@to)
          value = node.instance_variable_get(:@from).name

          if variable == 'translation_enabled'
            @translation_enabled = value
            break
          end
        end
      end

      @translation_enabled = true if @translation_enabled.nil?
      @translation_enabled
    end

    def content_tags
      @content_tags ||= connected_content_tags.each_with_object([]) do |tag, ret|
        tag = ContentTag.new(self, tag)
        ret << tag if tag.contains_translations?
      end
    end

    def connected_content_tags
      # this assumes these are basically at the top of the template and not
      # nested inside other liquid tags
      @connected_content_tags ||= liquid_template.root.nodelist.select do |node|
        node.is_a?(Txbr::Liquid::ConnectedContentTag)
      end
    end

    # Designed to replace special Braze variables like {{campaign.${api_id}}}
    # and ${first_name}, which Liquid can't natively handle. If the variable
    # exists in the given variables hash, replace it with the value directly.
    # Otherwise, transform the var into something Liquid-friendly so it
    # doesn't jam up the parser.
    def prerender(source, variables)
      source.gsub(/(?:\{\s*\{\s*)?(?:[\w\-\_\.\[\]]+\.)?\$\{\s*[\w\-\.\[\]]+\s*\}?\s*(?:\}?\s*\})?/) do |orig|
        plain = orig.sub(/\A\{\{/, '').sub(/\}\}\z/, '')

        result = if val = variables[plain]
          "\"#{val}\""
        else
          normalize_braze_var(orig)
        end

        if orig.tr(' ', '').start_with?('{{')
          result = "{{#{result}"
        end

        if orig.tr(' ', '').end_with?('}}')
          result << '}}'
        end

        result
      end
    end

    def normalize_braze_var(var)
      "__braze__#{var.gsub(/[^\w\-\.\[\]]/, '')}"
    end
  end
end
