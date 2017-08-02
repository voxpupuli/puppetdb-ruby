require 'bundler/gem_tasks'

begin
  require 'github_changelog_generator/task'
  GitHubChangelogGenerator::RakeTask.new :changelog do |config|
    version = PuppetDB::VERSION
    config.future_release = "v#{version}"
    config.header = "# Change log\n\nAll notable changes to this project will be documented in this file.\nEach new release typically also includes the latest modulesync defaults.\nThese should not impact the functionality of the module."
    config.exclude_labels = %w{duplicate question invalid wontfix wont-fix modulesync}
    config.user = 'voxpupuli'
  end
rescue LoadError
end