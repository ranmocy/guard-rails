source "http://rubygems.org"

# Specify your gem's dependencies in guard-rails.gemspec
gemspec
gem 'rake'
gem 'guard'
gem 'guard-bundler'
gem 'guard-rspec'

# Notification System
gem 'terminal-notifier-guard', require: RUBY_PLATFORM.downcase.include?("darwin") ? 'terminal-notifier-guard' : nil
gem 'libnotify', require: RUBY_PLATFORM.downcase.include?("linux") ? 'libnotify' : nil

# Test Coverage
gem "codeclimate-test-reporter", group: :test, require: nil
