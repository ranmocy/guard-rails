require 'bundler'
Bundler::GemHelper.install_tasks

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec)

require 'rake/version_task'
Rake::VersionTask.new

include Rake::DSL if defined?(Rake::DSL)

task :default => 'spec'

desc 'Push everywhere!'
task :publish do
  system %{git push}
  system %{git push --tags}
end

task :contributors do
    puts `git summary | grep "%" | sed 's/ *[0-9]*\.[0-9]*%//g' | cut -f2 | sed 's/^/* /g'`
end
