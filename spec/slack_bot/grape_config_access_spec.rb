require "spec_helper"
require "grape"
require "rack/test"

describe SlackBot::GrapeHelpers do
  include Rack::Test::Methods

  def app
    @app ||= Class.new(Grape::API) do
      include SlackBot::GrapeExtension

      helpers do
        def verify_slack_signature!
          true
        end
      end

      get "/config-probe" do
        grape_config = instance_variable_get(:@config)
        {
          slack_bot_config_class: slack_bot_config.class.name,
          grape_config_class: grape_config.class.name
        }
      end
    end
  end

  it "keeps SlackBot config off Grape endpoint @config" do
    get "/config-probe"
    body = JSON.parse(last_response.body)

    expect(last_response.status).to eq(200)
    expect(body["slack_bot_config_class"]).to eq("SlackBot::Config")
    expect(body["grape_config_class"]).not_to eq("SlackBot::Config")
  end
end
