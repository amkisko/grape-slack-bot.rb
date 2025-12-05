require "simplecov"
require "simplecov-cobertura"
require "simplecov_json_formatter"

SimpleCov.start do
  track_files "{lib,app}/**/*.rb"
  add_filter "/lib/tasks/"
  formatter SimpleCov::Formatter::MultiFormatter.new([
    SimpleCov::Formatter::HTMLFormatter,
    SimpleCov::Formatter::CoberturaFormatter,
    SimpleCov::Formatter::JSONFormatter
  ])
end

# Require standard library Logger before ActiveSupport (required for Rails 6.1 + Ruby 3.1+)
require "logger"

require "active_support"
require "active_support/json"

require "slack_bot"

Dir[File.expand_path("support/**/*.rb", __dir__)].each { |f| require_relative f }

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
