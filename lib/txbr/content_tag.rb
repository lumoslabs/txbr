module Txbr
  class ContentTag
    attr_reader :liquid_template, :liquid_tag

    def initialize(liquid_template, liquid_tag)
      @liquid_template = liquid_template
      @liquid_tag = liquid_tag
    end

    def metadata
      @metadata ||= begin
        # Render the template to implicitly populate the metadata hash inside
        # the liquid tag object. We do this because we encourage templates to
        # set local variables for the project and resource slugs. It's less
        # error-prone to let Liquid do the template evaluation instead of
        # grepping through the nodelist looking for assignment statements.
        liquid_template.render
        liquid_tag.metadata
      end
    end

    def strings_manifest
      @strings_manifest ||= StringsManifest.new.tap do |manifest|
        extract_strings_from(liquid_template.root, manifest)
      end
    end

    def contains_translations?
      metadata.project_slug && metadata.resource_slug && metadata.prefix
    end

    private

    def extract_strings_from(root, manifest)
      return unless root.nodelist

      root.nodelist.each do |node|
        case node
          # We only care about Liquid variables, which are written
          # like {{prefix.foo.bar}}. We identify the prefix (i.e.
          # the first lookup, or path segment) to verify it's
          # associated with a connected_content call. Then we add
          # the prefix and the rest of the lookups to the strings
          # manifest along with the value. The prefix is used to
          # divide the strings into individual Transifex resources
          # while the rest of the lookups form the string's key.
          when ::Liquid::Variable
            next unless node.name.is_a?(::Liquid::VariableLookup)

            string_prefix = node.name.name
            path = node.name.lookups

            # the English translation (or whatever language your
            # source strings are written in) is provided using
            # Liquid's built-in "default" filter
            next unless string_prefix == metadata.prefix
            default = node.filters.find { |f| f.first == 'default' }

            manifest.add(path, default&.last&.first)
        end

        if node.respond_to?(:nodelist)
          extract_strings_from(node, manifest)
        end
      end
    end
  end
end
