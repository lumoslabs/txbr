module Txbr
  module Commands
    def self.upload_all
      Txbr::Config.projects.each do |project|
        begin
          Txbr::Uploader.new(project).upload_all
        rescue => e
          Txgh.events.publish_error!(e)
        end
      end
    end
  end
end
