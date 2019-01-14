module Txbr
  class Metadata
    ASSIGNMENTS = %w(project_slug resource_slug prefix)

    attr_reader :project_slug, :resource_slug, :prefix

    def initialize(options = {})
      @project_slug = options.fetch('project_slug')
      @resource_slug = options.fetch('resource_slug')
      @prefix = options.fetch('prefix')
    end

    def ==(other)
      project_slug == other.project_slug &&
        resource_slug == other.resource_slug &&
        prefix == prefix
    end

    def eql?(other)
      hash == other.hash
    end

    def hash
      h = 7
      h = 31 * h + project_slug.hash
      h = 31 * h + resource_slug.hash
      h = 31 * h + prefix.hash
    end
  end
end
