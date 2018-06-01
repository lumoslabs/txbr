require 'rake'

namespace :txbr do
  task :upload do
    Txbr::Commands.upload_all
  end
end
