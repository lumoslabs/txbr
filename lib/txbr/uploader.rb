module Txbr
  class Uploader
    attr_reader :project

    def initialize(project)
      @project = project
    end

    def upload_all
      project.handler.each_item do |item|
        upload_item(item)
      end
    end

    def upload_item(item)
      item.each_resource do |resource|
        upload_resource(resource)
      end
    end

    private

    def upload_resource(resource)
      stream = StringIO.new
      resource.write_to(stream)
      project.transifex_api.create_or_update(
        resource.tx_resource, stream.string
      )
    rescue ::Txgh::TransifexApiError => e
      Txgh.events.publish_error!(e)
    end
  end
end
