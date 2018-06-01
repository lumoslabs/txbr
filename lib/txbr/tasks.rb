require 'rake'
require 'txbr'

namespace :txbr do
  task :upload_all do
    Txbr::Commands.upload_all
  end
end
