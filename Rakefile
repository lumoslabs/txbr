$:.push('./lib')

load 'txbr/tasks.rb'

require 'rspec/core/rake_task'
require 'rubygems/package_task'
require './lib/txbr'

Bundler::GemHelper.install_tasks

desc 'Run specs'
RSpec::Core::RakeTask.new do |t|
  t.pattern = './spec/**/*_spec.rb'
end

namespace :version do
  task :bump, [:level] do |t, args|
    levels = %w(major minor patch)
    level = args[:level]

    until levels.include?(level)
      STDOUT.write("Indicate version bump level (#{levels.join(', ')}): ")
      level = STDIN.gets.strip

      unless levels.include?(level)
        puts "That's not a valid version bump level, try again."
      end
    end

    level.strip!

    major, minor, patch = Txbr::VERSION.split('.').map(&:to_i)

    case level
      when 'major'
        major += 1; minor = 0; patch = 0
      when 'minor'
        minor += 1; patch = 0
      when 'patch'
        patch += 1
    end

    new_version = [major, minor, patch].join('.')
    puts "Bumping from #{Txbr::VERSION} to #{new_version}"

    # rewrite version.rb
    version_file = './lib/txbr/version.rb'
    contents = File.read(version_file)
    contents.sub!(/VERSION\s*=\s['"][\d.]+['"]$/, "VERSION = '#{new_version}'")
    File.write(version_file, contents)

    # update constant in case other rake tasks run in this process afterwards
    Txbr::VERSION.replace(new_version)
  end

  task :history do
    history = File.read('CHANGELOG.md')
    history = "# #{Txbr::VERSION}\n* \n\n#{history}"
    File.write('CHANGELOG.md', history)
    system "vi CHANGELOG.md"
  end

  task :commit_and_push do
    system "git add lib/txbr/version.rb"
    system "git add CHANGELOG.md"
    system "git commit -m 'Bumping version to #{Txbr::VERSION}'"
    system "git push origin HEAD"
  end
end

DOCKER_REPO = 'quay.io/lumoslabs/txbr'

namespace :publish do
  task :all do
    task_names = %w(
      version:bump version:history version:commit_and_push
      publish:tag publish:build_gem publish:publish_gem
      publish:update_docker_base_image publish:build_docker
      publish:publish_docker
    )

    task_names.each do |task_name|
      STDOUT.write "About to execute #{task_name}, continue? (yes/no/skip): "
      answer = STDIN.gets

      case answer.downcase
        when /ye?s?/
          Rake::Task[task_name].invoke
        when /no?/
          puts "Exiting!"
          exit 0
        else
          puts "Skipping #{task_name}"
      end
    end
  end

  task :tag do
    system("git tag -a v#{Txbr::VERSION} && git push origin --tags")
  end

  task :build_gem => [:build]  # use preexisting build task from rubygems/package_task

  task :publish_gem do
    system("gem push pkg/txbr-#{Txbr::VERSION}.gem")
  end

  task :update_docker_base_image do
    system("docker pull ruby:2.5")
  end

  task :build_docker do
    require './lib/txbr/version'
    version = Txbr::VERSION

    system("docker build -t #{DOCKER_REPO}:latest -t #{DOCKER_REPO}:v#{version} .")
  end

  task :publish_docker do
    require './lib/txbr/version'
    version = Txbr::VERSION

    system("docker push #{DOCKER_REPO}:latest")
    system("docker push #{DOCKER_REPO}:v#{version}")
  end
end

task publish: 'publish:all'
