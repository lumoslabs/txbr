module Txbr
  class TemplateGroup
    attr_reader :template_name, :templates, :project

    def initialize(template_name, templates, project)
      @template_name = template_name
      @templates = templates
      @project = project
    end

    def each_resource
      return to_enum(__method__) unless block_given?

      templates
        .flat_map { |tmpl| tmpl.each_content_tag.to_a }
        .group_by(&:metadata)
        .each do |metadata, content_tags|
          strings = content_tags.inject(StringsManifest.new) do |manifest, content_tag|
            manifest.merge(content_tag.strings_manifest)
          end

          yield to_resource(metadata, strings)
        end
    end

    private

    def to_resource(metadata, strings_manifest)
      phrases = strings_manifest.each_string
        .reject { |_, value| value.nil? }
        .map do |path, value|
          { 'key' => path.join('.'), 'string' => value }
        end

      return nil if phrases.empty?

      resource = Txgh::TxResource.new(
        metadata.project_slug,
        metadata.resource_slug,
        project.strings_format,
        project.source_lang,
        template_name,
        {},   # lang_map (none)
        nil   # translation_file (none)
      )

      Txgh::ResourceContents.from_phrase_list(resource, phrases)
    end
  end
end
