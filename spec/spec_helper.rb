if ENV['CI']
  require "codeclimate-test-reporter"
  CodeClimate::TestReporter.start
else
  require 'simplecov'
  SimpleCov.start
end

require 'guard/rails'

RSpec.configure do |c|
  c.mock_with :rr
end
