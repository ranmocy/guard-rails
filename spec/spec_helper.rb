require "codeclimate-test-reporter"
CodeClimate::TestReporter.start

RSpec.configure do |c|
  c.mock_with :rr
end
