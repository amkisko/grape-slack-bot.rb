require "grape"
require "rack/test"

RSpec.shared_context "with signed Slack requests" do
  include Rack::Test::Methods

  let(:config) { SlackBot::Config.new }
  let(:user) { Struct.new(:id).new("U1") }

  def app
    bot_config = config
    bot_user = user
    @app ||= Class.new(Grape::API) do
      include SlackBot::GrapeExtension

      helpers do
        define_method(:slack_bot_config) { bot_config }
        define_method(:current_user) { bot_user }
      end
    end
  end

  around do |example|
    previous = ENV.to_h.slice("SLACK_TEAM_ID", "SLACK_SIGNING_SECRET")
    ENV.update("SLACK_TEAM_ID" => "T1", "SLACK_SIGNING_SECRET" => "test_transport")
    example.run
  ensure
    ENV.delete("SLACK_TEAM_ID")
    ENV.delete("SLACK_SIGNING_SECRET")
    ENV.update(previous)
  end

  def signed_headers(body, content_type = "application/x-www-form-urlencoded")
    timestamp = Time.now.to_i
    signature = OpenSSL::HMAC.hexdigest("SHA256", "test_transport", "v0:#{timestamp}:#{body}")
    {
      "CONTENT_TYPE" => content_type,
      "HTTP_X_SLACK_REQUEST_TIMESTAMP" => timestamp.to_s,
      "HTTP_X_SLACK_SIGNATURE" => "v0=#{signature}"
    }
  end

  def send_payload(type, path: "/interactions", **fields)
    payload = {type: type, team: {id: "T1"}, user: {id: "U1"}}.merge(fields)
    body = Rack::Utils.build_query(payload: JSON.generate(payload))
    post path, body, signed_headers(body)
  end
end
