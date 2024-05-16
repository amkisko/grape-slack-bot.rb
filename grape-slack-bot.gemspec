Gem::Specification.new do |gem|
  gem.name = "grape-slack-bot"
  gem.version = File.read(File.expand_path("../lib/slack_bot.rb", __FILE__)).match(/VERSION\s*=\s*"(.*?)"/)[1]

  repository_url = "https://github.com/amkisko/grape-slack-bot.rb"
  root_files = %w[CHANGELOG.md LICENSE.md README.md]
  root_files << "#{gem.name}.gemspec"

  gem.license = "MIT"

  gem.platform = Gem::Platform::RUBY

  gem.authors = ["Andrei Makarov"]
  gem.email = ["andrei@kiskolabs.com"]
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

  gem.executables = Dir.glob("bin/*").map { |f| File.basename(f) }
  gem.files = Dir.glob("lib/**/*.rb") + Dir.glob("bin/**/*") + root_files

  gem.required_ruby_version = ">= 3"
  gem.require_paths = ["lib"]

  gem.add_runtime_dependency "rack", "> 2"
  gem.add_runtime_dependency "grape", "> 1"
  gem.add_runtime_dependency "faraday", "> 1"
  gem.add_runtime_dependency "activesupport", "> 5"

  gem.add_development_dependency "bundler", "~> 2"
  gem.add_development_dependency "pry", "~> 0.14"
  gem.add_development_dependency "rspec", "~> 3"
  gem.add_development_dependency "webmock", "~> 3"
  gem.add_development_dependency "simplecov", "~> 0.21"
  gem.add_development_dependency "simplecov-cobertura", "~> 2"
  gem.add_development_dependency "standard", "~> 1"
  gem.add_development_dependency "standard-performance", "~> 1"
  gem.add_development_dependency "standard-rspec", "~> 0.2"
end
