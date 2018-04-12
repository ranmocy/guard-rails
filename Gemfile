source "http://rubygems.org"

gemspec

# Development tools
group :development do
  gem 'rspec'
  gem 'fakefs'
  gem 'version'

  gem 'rake'
  gem 'guard-bundler'
  gem 'guard-rspec'

  # Notification System
  gem 'terminal-notifier'
  gem 'terminal-notifier-guard', require: RUBY_PLATFORM.downcase.include?("darwin") ? 'terminal-notifier-guard' : nil
  gem 'libnotify', require: RUBY_PLATFORM.downcase.include?("linux") ? 'libnotify' : nil
end

group :test do
  gem "simplecov"
  gem "codeclimate-test-reporter", "~> 1.0"
end
