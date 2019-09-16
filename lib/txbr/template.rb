module Txbr
  class Template
    attr_reader :id, :liquid_template

    def initialize(id, liquid_template)
      @id = id
      @liquid_template = liquid_template
    end

    def each_content_tag
      return to_enum(__method__) unless block_given?

      content_tags.each do |content_tag|
        next unless translation_enabled?
        yield content_tag
      end
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
        tag = ContentTag.new(liquid_template, tag)
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
  end
end
