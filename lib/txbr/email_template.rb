require 'liquid'
require 'txgh'

module Txbr
  class EmailTemplate
    attr_reader :project, :email_template_id

    def initialize(project, email_template_id)
      @project = project
      @email_template_id = email_template_id
    end

    def each_resource
      return to_enum(__method__) unless block_given?

      strings.prefixes.each do |prefix|
        resource_slug = Txgh::Utils.slugify("#{api_identifier}-#{prefix}")
        phrases = strings.each_string(prefix)
          .reject { |_, value| value.nil? }
          .map do |path, value|
            { 'key' => path.join('.'), 'string' => value }
          end

        next if phrases.empty?

        resource = Txgh::TxResource.new(
          project.project_slug,
          resource_slug,
          project.strings_format,
          project.source_lang,
          template_name,
          {},   # lang_map (none)
          nil   # translation_file (none)
        )

        yield Txgh::ResourceContents.from_phrase_list(resource, phrases)
      end
    end

    private

    def strings
      @strings ||= components.inject(StringsManifest.new) do |manifest, component|
        manifest.merge(component.strings)
      end
    end

    def components
      @components ||= %w(template subject preheader).map do |name|
        EmailTemplateComponent.new(
          Liquid::Template.parse(contents[name])
        )
      end
    end

    def template_name
      contents['name']
    end

    def api_identifier
      contents['api_identifier']
    end

    def contents
      @contents ||= project.braze_api.get_email_template(
        email_template_id: email_template_id
      )
    end
  end


  class EmailTemplateComponent
    attr_reader :liquid_template

    def initialize(liquid_template)
      @liquid_template = liquid_template
    end

    def strings
      @strings ||= StringsManifest.new.tap do |manifest|
        liquid_template.root.nodelist.each do |node|
          case node
            # We only care about Liquid variables, which are written
            # like {{prefix.foo.bar}}. We identify the prefix (i.e.
            # the first lookup, or path segment) to verify it's
            # associated with a connected_content call. Then we add
            # the prefix and the rest of the lookups to the strings
            # manifest along with the value. The prefix is used to
            # divide the strings into individual Transifex resources
            # while the rest of the lookups form the string's key.
            when Liquid::Variable
              prefix = node.name.name
              path = node.name.lookups

              # the English translation (or whatever language your
              # source strings are written in) is provided using
              # Liquid's built-in "default" filter
              next unless connected_content_prefixes.include?(prefix)
              default = node.filters.find { |f| f.first == 'default' }

              manifest.add(prefix, path, default&.last&.first)
          end
        end
      end
    end

    private

    def connected_content_prefixes
      @connected_content_prefixes ||= connected_content_tags.map(&:prefix)
    end

    def connected_content_tags
      @connected_content_tags ||= liquid_template.root.nodelist.select do |node|
        node.is_a?(Txbr::ConnectedContentTag)
      end
    end
  end
end
