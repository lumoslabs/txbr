module Txbr
  def self.upload_all
    Txbr::Config.projects.each do |project|
      begin
        Txbr::Uploader.new(project).upload_all
      rescue => e
        puts "An error occurred: #{e.message}"
        puts e.backtrace
      end
    end
  end
end
