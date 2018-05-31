require 'liquid'

module Txbr
  class EmailTemplate
    attr_reader :project, :email_template_id

    def initialize(project, email_template_id)
      @project = project
      @email_template_id = email_template_id
    end

    def each_resource
      return to_enum(__method__) unless block_given?

      strings_map.each_pair do |project_slug, resource_map|
        resource_map.each_pair do |resource_slug, strings_manifest|
          strings_manifest.prefixes.each do |prefix|
            phrases = strings_manifest.each_string(prefix)
              .reject { |_, value| value.nil? }
              .map do |path, value|
                { 'key' => path.join('.'), 'string' => value }
              end

            next if phrases.empty?

            resource = Txgh::TxResource.new(
              project_slug,
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
      end
    end

    private

    def strings_map
      @strings_map ||= %w(template subject preheader).each_with_object({}) do |name, ret|
        component = EmailTemplateComponent.new(
          Liquid::Template.parse(details[name])
        )

        next unless component.translation_enabled?

        (ret[component.project_slug] ||= {}).tap do |proj_map|
          (proj_map[component.resource_slug] ||= StringsManifest.new).tap do |manifest|
            manifest.merge!(component.strings)
          end
        end
      end
    end

    def template_name
      details['name']
    end

    def details
      @details ||= project.braze_api.get_email_template_details(
        email_template_id: email_template_id
      )
    end
  end
end
