require 'bundler'
Bundler::GemHelper.install_tasks

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec)

require 'rake/version_task'
Rake::VersionTask.new

include Rake::DSL if defined?(Rake::DSL)
RVM_PREFIX = "rvm 1.8.7,1.9.3,2.0.0 do"


namespace :spec do
  desc "Run on three Rubies"
  task :platforms do
    exit $?.exitstatus unless system "#{RVM_PREFIX} bundle install 2>&1 1>/dev/null "
    exit $?.exitstatus unless system "#{RVM_PREFIX} bundle exec rake spec"
  end
end

task :default => 'spec:platforms'

desc 'Push everywhere!'
task :publish do
  system %{git push origin}
  system %{git push guard}
  system %{git push gitcafe}
  system %{git push origin --tags}
  system %{git push guard --tags}
  system %{git push gitcafe --tags}
end
