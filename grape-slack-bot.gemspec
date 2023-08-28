# -*- encoding: utf-8 -*-
require File.expand_path('../lib/grape_slack_bot/version', __FILE__)

Gem::Specification.new do |gem|
  gem.name = "grape-slack-bot"
  gem.version = GrapeSlackBot::VERSION

  repository_url = "https://github.com/amkisko/grape-slack-bot.rb"
  root_files = %w(CHANGELOG.md LICENSE.md README.md)
  root_files << "#{gem.name}.gemspec"

  gem.license = "MIT"

  gem.platform = Gem::Platform::RUBY

  gem.authors = ["Andrei Makarov"]
  gem.email = ["andrei@kiskolabs.com"]
  gem.homepage = repository_url
  gem.summary = %q{Slack bot implementation for ruby-grape}
  gem.description = gem.summary
  gem.metadata = {
    "homepage" => repository_url,
    "source_code_uri" => repository_url,
    "bug_tracker_uri" => "#{repository_url}/issues",
    "changelog_uri" => "#{repository_url}/blob/main/CHANGELOG.md",
    "rubygems_mfa_required" => "true"
  }

  gem.executables = Dir.glob("bin/*").map{ |f| File.basename(f) }
  gem.files = Dir.glob("lib/**/*.rb") + Dir.glob("bin/**/*") + root_files
  gem.test_files = Dir.glob("spec/**/*_spec.rb")

  gem.required_ruby_version = ">= 1.9.3"
  gem.require_paths = ["lib"]

  gem.add_runtime_dependency 'omniauth-slack-openid', '~> 1'
  gem.add_runtime_dependency 'grape', '~> 1'

  gem.add_development_dependency 'bundler', '~> 2'
  gem.add_development_dependency 'rake', '~> 13'
  gem.add_development_dependency 'pry-byebug'
  gem.add_development_dependency 'rspec', '~> 3'
end
