Gem::Specification.new do |gem|
  gem.name = "grape-slack-bot"
  gem.version = File.read(File.expand_path("../lib/slack_bot.rb", __FILE__)).match(/VERSION\s*=\s*"(.*?)"/)[1]

  repository_url = "https://github.com/amkisko/grape-slack-bot.rb"
  root_files = %w[CHANGELOG.md LICENSE.md README.md]
  root_files << "#{gem.name}.gemspec"

  gem.license = "MIT"

  gem.platform = Gem::Platform::RUBY

  gem.authors = ["Andrei Makarov"]
  gem.email = ["contact@kiskolabs.com"]
  gem.homepage = repository_url
  gem.summary = "Slack bot implementation for ruby-grape"
  gem.description = gem.summary
  gem.metadata = {
    "homepage" => repository_url,
    "source_code_uri" => repository_url,
    "bug_tracker_uri" => "#{repository_url}/issues",
    "changelog_uri" => "#{repository_url}/blob/main/CHANGELOG.md",
    "rubygems_mfa_required" => "true"
  }

  gem.files = Dir.glob("lib/**/*.rb") + Dir.glob("sig/**/*.rbs") + root_files

  gem.required_ruby_version = ">= 3"
  gem.require_paths = ["lib"]

  gem.add_runtime_dependency "rack", "~> 3.0"
  gem.add_runtime_dependency "grape", ">= 1.6", "< 4.0"
  gem.add_runtime_dependency "faraday", "~> 2.0"
  gem.add_runtime_dependency "activesupport", ">= 6.1", "< 9.0"

  gem.add_development_dependency "rspec", "~> 3"
  gem.add_development_dependency "polyrun", "~> 1.5.0"
  gem.add_development_dependency "webmock", "~> 3"
  gem.add_development_dependency "rake", "~> 13"
  gem.add_development_dependency "standard", "~> 1.52"
  gem.add_development_dependency "standard-custom", "~> 1.0"
  gem.add_development_dependency "standard-performance", "~> 1.8"
  gem.add_development_dependency "standard-rspec", "~> 0.3"
  gem.add_development_dependency "rubocop-rspec", "~> 3.8"
  gem.add_development_dependency "rubocop-thread_safety", "~> 0.7"
  gem.add_development_dependency "appraisal", "~> 2"
  gem.add_development_dependency "memory_profiler", "~> 1"
  gem.add_development_dependency "rbs", "~> 3"
  gem.add_development_dependency "rack-test", "~> 2"
end
