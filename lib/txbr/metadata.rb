module Txbr
  class Metadata
    ASSIGNMENTS = %w(project_slug resource_slug prefix)

    attr_reader :project_slug, :resource_slug, :prefix

    def initialize(options = {})
      @project_slug = options['project_slug']
      @resource_slug = options['resource_slug']
      @prefix = options['prefix']
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
