module Txbr
  class EmailTemplateComponent
    ASSIGNMENTS = %w(project_slug resource_slug translation_enabled)

    attr_reader :liquid_template

    def initialize(liquid_template)
      @liquid_template = liquid_template
    end

    def project_slug
      # blow up with KeyError if not found
      assignments.fetch('project_slug')
    end

    def resource_slug
      # blow up with KeyError if not found
      assignments.fetch('resource_slug')
    end

    def translation_enabled?
      # translation is disabled by default
      assignments.fetch('translation_enabled', true)
    end

    def assignments
      @assignments ||= {}.tap do |assgn|
        liquid_template.root.nodelist.each do |node|
          case node
            when Liquid::Assign
              to = node.instance_variable_get(:@to)

              if ASSIGNMENTS.include?(to)
                from = node.instance_variable_get(:@from).name
                assgn[to] = from
              end
          end
        end
      end
    end

    def strings
      @strings ||= StringsManifest.new.tap do |manifest|
        extract_strings_from(liquid_template.root, manifest)
      end
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
          when Liquid::Variable
            next unless node.name.is_a?(Liquid::VariableLookup)

            prefix = node.name.name
            path = node.name.lookups

            # the English translation (or whatever language your
            # source strings are written in) is provided using
            # Liquid's built-in "default" filter
            next unless connected_content_prefixes.include?(prefix)
            default = node.filters.find { |f| f.first == 'default' }

            manifest.add(path, default&.last&.first)
        end

        if node.respond_to?(:nodelist)
          extract_strings_from(node, manifest)
        end
      end
    end

    def connected_content_prefixes
      @connected_content_prefixes ||= connected_content_tags.map(&:prefix)
    end

    def connected_content_tags
      # this assumes these are basically at the top of the template and not
      # nested inside other liquid tags
      @connected_content_tags ||= liquid_template.root.nodelist.select do |node|
        node.is_a?(Txbr::ConnectedContentTag)
      end
    end
  end
end
