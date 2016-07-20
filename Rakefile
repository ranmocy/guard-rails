require 'bundler'
Bundler::GemHelper.install_tasks

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec)

require 'rake/version_task'
Rake::VersionTask.new

include Rake::DSL if defined?(Rake::DSL)
RVM_DO_ALL = "rvm all do"


namespace :spec do
  desc "Run on three Rubies"
  task :platforms do
    exit $?.exitstatus unless system "#{RVM_DO_ALL} bundle install 2>&1 1>/dev/null "
    exit $?.exitstatus unless system "#{RVM_DO_ALL} bundle exec rake spec"
  end
end

task :default => 'spec:platforms'

desc 'Push everywhere!'
task :publish do
  system %{git push}
  system %{git push --tags}
end
