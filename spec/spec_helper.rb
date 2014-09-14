require "codeclimate-test-reporter"
CodeClimate::TestReporter.start
# require 'simplecov'
# SimpleCov.start

require 'guard/rails'

RSpec.configure do |c|
  c.mock_with :rr
end
