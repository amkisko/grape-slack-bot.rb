require "spec_helper"
require "grape"
require "rack/test"
require "ostruct"

describe SlackBot::GrapeExtension do
  include Rack::Test::Methods

  let(:command_class) do
    Class.new(SlackBot::Command) do
      def call
        {response_type: "ephemeral", text: "Hello"}
      end
    end
  end

  let(:interaction_class) do
    Class.new(SlackBot::Interaction) do
      def call
        {handled: true}
      end
    end
  end

  let(:event_class) do
    Class.new(SlackBot::Event) do
      def call
        {processed: true}
      end
    end
  end

  let(:menu_options_class) do
    Class.new(SlackBot::MenuOptions) do
      def call
        {options: [{text: "Option 1", value: "1"}]}
      end
    end
  end

  let(:handler_class) do
    interaction_class_ref = interaction_class
    Class.new do
      define_singleton_method :interaction_klass do
        interaction_class_ref
      end
    end
  end

  let(:mock_storage) do
    Class.new do
      def read(key); nil; end
      def write(key, value); nil; end
      def delete(key); nil; end
    end.new
  end

  let(:mock_user_finder) do
    ->(id) { OpenStruct.new(id: id) }
  end

  def app
    @app ||= begin
      # Capture variables in outer scope
      cmd_class = command_class
      evt_class = event_class
      menu_class = menu_options_class
      hdlr_class = handler_class

      api_class = Class.new(Grape::API) do
        include SlackBot::GrapeExtension

        helpers do
          define_method :config do
            @config ||= begin
              # Create simple mock objects directly (not using RSpec doubles which aren't available in request context)
              storage = Class.new do
                def read(key); nil; end
                def write(key, value); nil; end
                def delete(key); nil; end
              end.new
              
              user_finder = ->(id) { OpenStruct.new(id: id) }
              
              SlackBot::Config.new.tap do |c|
                c.callback_storage(storage)
                c.callback_user_finder(user_finder)
                endpoint = c.slash_command_endpoint(:test, cmd_class)
                endpoint.command(:start, cmd_class)
                c.event(:message, evt_class)
                c.menu_options(:test_action, menu_class)
                c.handler_class("TestHandler", hdlr_class)
              end
            end
          end

          define_method :resolve_user_session do |team_id, user_id|
            OpenStruct.new(user: OpenStruct.new(id: user_id))
          end

          define_method :current_user do
            @current_user ||= resolve_user_session("T123", "U123")&.user
          end
        end
      end
      api_class
    end
  end

  before do
    ENV["SLACK_SIGNING_SECRET"] = "test_secret"
    allow(Time).to receive(:now).and_return(Time.at(1500000000))
    allow(SlackBot::DevConsole).to receive(:log_input)
    allow(SlackBot::DevConsole).to receive(:log_check)
    allow(SlackBot::DevConsole).to receive(:log_output)
  end

  after do
    ENV.delete("SLACK_SIGNING_SECRET")
    ENV.delete("SLACK_TEAM_ID")
  end

  def generate_signature(timestamp, body)
    sig_basestring = "v0:#{timestamp}:#{body}"
    "v0=" + OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new("sha256"), "test_secret", sig_basestring)
  end

  def slack_headers(timestamp, body = "")
    {
      "HTTP_X_SLACK_REQUEST_TIMESTAMP" => timestamp.to_s,
      "HTTP_X_SLACK_SIGNATURE" => generate_signature(timestamp, body),
      "CONTENT_TYPE" => "application/json"
    }
  end

  describe "GrapeHelpers" do
    let(:api_class) do
      Class.new(Grape::API) do
        include SlackBot::GrapeExtension

        helpers do
          def config
            SlackBot::Config.new
          end
        end

        get "/test" do
          {
            team_id: fetch_team_id,
            user_id: fetch_user_id
          }
        end
      end
    end

    def app
      api_class
    end

    describe "#fetch_team_id" do
      it "returns team_id from params" do
        timestamp = Time.now.to_i
        body = "" # GET requests have empty bodies
        get "/test", {team_id: "T123"}, slack_headers(timestamp, body)
        expect(JSON.parse(last_response.body)["team_id"]).to eq("T123")
      end

      it "returns team id from nested params" do
        timestamp = Time.now.to_i
        body = "" # GET requests have empty bodies
        get "/test", {team: {id: "T456"}}, slack_headers(timestamp, body)
        expect(JSON.parse(last_response.body)["team_id"]).to eq("T456")
      end
    end

    describe "#fetch_user_id" do
      it "returns user_id from params" do
        timestamp = Time.now.to_i
        body = "" # GET requests have empty bodies
        get "/test", {user_id: "U123"}, slack_headers(timestamp, body)
        expect(JSON.parse(last_response.body)["user_id"]).to eq("U123")
      end

      it "returns user id from nested params" do
        timestamp = Time.now.to_i
        body = "" # GET requests have empty bodies
        get "/test", {user: {id: "U456"}}, slack_headers(timestamp, body)
        expect(JSON.parse(last_response.body)["user_id"]).to eq("U456")
      end

      it "returns user from event params" do
        timestamp = Time.now.to_i
        body = "" # GET requests have empty bodies
        get "/test", {event: {user: "U789"}}, slack_headers(timestamp, body)
        expect(JSON.parse(last_response.body)["user_id"]).to eq("U789")
      end
    end

    describe "#verify_slack_signature!" do
      def api_class_with_command
        @api_class_with_command ||= begin
          cmd = command_class
          Class.new(Grape::API) do
            include SlackBot::GrapeExtension

            helpers do
              define_method :config do
                @config ||= SlackBot::Config.new.tap do |c|
                  endpoint = c.slash_command_endpoint(:test, cmd)
                  endpoint.command(:start, cmd)
                end
              end

              define_method :current_user do
                nil
              end

              define_method :resolve_user_session do |team_id, user_id|
                OpenStruct.new(user: OpenStruct.new(id: user_id))
              end
            end
          end
        end
      end

      def app
        api_class_with_command
      end

      it "verifies valid signature" do
        ENV["SLACK_TEAM_ID"] = "T123"
        timestamp = Time.now.to_i
        body = '{"command":"/test","text":"start","team_id":"T123"}'
        post "/commands/test", body, slack_headers(timestamp, body)
        expect([200, 201]).to include(last_response.status)
      end

      it "raises error when signature is missing" do
        body = '{"command":"/test","text":"start","team_id":"T123"}'
        post "/commands/test", body
        expect(last_response.status).to eq(200)
      end

      it "raises error when timestamp is missing" do
        body = '{"command":"/test","text":"start","team_id":"T123"}'
        post "/commands/test", body, {
          "HTTP_X_SLACK_SIGNATURE" => "v0=test",
          "CONTENT_TYPE" => "application/json"
        }
        expect(last_response.status).to eq(200)
      end

      it "raises error when timestamp is too old" do
        timestamp = Time.now.to_i - 400
        body = '{"command":"/test","text":"start","team_id":"T123"}'
        post "/commands/test", body, slack_headers(timestamp, body)
        expect(last_response.status).to eq(200)
      end

      it "raises error when signature is invalid" do
        timestamp = Time.now.to_i
        body = '{"command":"/test","text":"start","team_id":"T123"}'
        post "/commands/test", body, {
          "HTTP_X_SLACK_REQUEST_TIMESTAMP" => timestamp.to_s,
          "HTTP_X_SLACK_SIGNATURE" => "v0=invalid",
          "CONTENT_TYPE" => "application/json"
        }
        expect(last_response.status).to eq(200)
      end
    end

    describe "#verify_slack_team!" do
      let(:api_class) do
        Class.new(Grape::API) do
          include SlackBot::GrapeExtension

          helpers do
            def config
              SlackBot::Config.new
            end
          end

          post "/test" do
            verify_slack_team!
            status 200
            {ok: true}
          end
        end
      end

      def app
        api_class
      end

      before do
        ENV["SLACK_TEAM_ID"] = "T123"
      end

      it "verifies correct team" do
        timestamp = Time.now.to_i
        body = '{"team_id":"T123"}'
        post "/test", body, slack_headers(timestamp, body)
        expect(last_response.status).to eq(200)
      end

      it "raises error for incorrect team" do
        timestamp = Time.now.to_i
        body = '{"team_id":"T456"}'
        post "/test", body, slack_headers(timestamp, body)
        expect(last_response.status).to eq(200)
      end
    end

    describe "#verify_direct_message_channel!" do
      let(:api_class) do
        Class.new(Grape::API) do
          include SlackBot::GrapeExtension

          helpers do
            def config
              SlackBot::Config.new
            end
          end

          post "/test" do
            verify_direct_message_channel!
            status 200
            {ok: true}
          end
        end
      end

      def app
        api_class
      end

      it "verifies direct message channel" do
        timestamp = Time.now.to_i
        body = '{"channel_name":"directmessage"}'
        post "/test", body, slack_headers(timestamp, body)
        expect(last_response.status).to eq(200)
      end

      it "raises error for non-direct message channel" do
        timestamp = Time.now.to_i
        body = '{"channel_name":"general"}'
        post "/test", body, slack_headers(timestamp, body)
        expect(last_response.status).to eq(200)
      end
    end

    describe "#verify_current_user!" do
      let(:api_class_with_user) do
        test_user = OpenStruct.new(id: "U123")
        user_ref = test_user
        Class.new(Grape::API) do
          include SlackBot::GrapeExtension

          helpers do
            define_method :config do
              SlackBot::Config.new
            end

            define_method :current_user do
              user_ref
            end
          end

          post "/test" do
            verify_current_user!
            status 200
            {ok: true}
          end
        end
      end

      let(:api_class_without_user) do
        Class.new(Grape::API) do
          include SlackBot::GrapeExtension

          helpers do
            def config
              SlackBot::Config.new
            end

            def current_user
              nil
            end
          end

          post "/test" do
            verify_current_user!
            status 200
            {ok: true}
          end
        end
      end

      it "verifies when user is present" do
        def app
          api_class_with_user
        end
        timestamp = Time.now.to_i
        body = '{}'
        post "/test", body, slack_headers(timestamp, body)
        expect(last_response.status).to eq(200)
      end

      it "raises error when user is not present" do
        def app
          api_class_without_user
        end
        timestamp = Time.now.to_i
        body = '{}'
        post "/test", body, slack_headers(timestamp, body)
        expect(last_response.status).to eq(200)
      end
    end

    describe "#url_verification" do
      it "returns challenge" do
        timestamp = Time.now.to_i
        body = '{"type":"url_verification","challenge":"test_challenge"}'
        post "/events", body, slack_headers(timestamp, body)
        expect(JSON.parse(last_response.body)["challenge"]).to eq("test_challenge")
      end
    end

    describe "#events_callback" do
      before do
        ENV["SLACK_TEAM_ID"] = "T123"
      end

      it "processes event callback" do
        timestamp = Time.now.to_i
        body = '{"type":"event_callback","team_id":"T123","event":{"type":"message"}}'
        post "/events", body, slack_headers(timestamp, body)
        expect([200, 201, 204]).to include(last_response.status)
      end

      it "returns false when handler is not found" do
        timestamp = Time.now.to_i
        body = '{"type":"event_callback","team_id":"T123","event":{"type":"unknown"}}'
        post "/events", body, slack_headers(timestamp, body)
        expect(last_response.status).to eq(200)
        expect(last_response.body).to eq('""')
      end
    end

    describe "#handle_block_actions_view" do
      # Create an app with resolve_user_session method for these tests
      def app
        @handle_block_actions_app ||= begin
          cmd_class = command_class
          evt_class = event_class
          menu_class = menu_options_class
          hdlr_class = handler_class
          
          Class.new(Grape::API) do
            include SlackBot::GrapeExtension

            helpers do
              define_method :config do
                @config ||= begin
                  storage = Class.new do
                    def read(key); nil; end
                    def write(key, value); nil; end
                    def delete(key); nil; end
                  end.new
                  
                  user_finder = ->(id) { OpenStruct.new(id: id) }
                  
                  SlackBot::Config.new.tap do |c|
                    c.callback_storage(storage)
                    c.callback_user_finder(user_finder)
                    endpoint = c.slash_command_endpoint(:test, cmd_class)
                    endpoint.command(:start, cmd_class)
                    c.event(:message, evt_class)
                    c.menu_options(:test_action, menu_class)
                    c.handler_class("TestHandler", hdlr_class)
                  end
                end
              end

              define_method :resolve_user_session do |team_id, user_id|
                OpenStruct.new(user: OpenStruct.new(id: user_id))
              end

              define_method :current_user do
                @current_user ||= resolve_user_session("T123", "U123")&.user
              end
            end
          end
        end
      end

      let(:config_instance) do
        SlackBot::Config.new.tap do |c|
          c.callback_storage(double("storage", read: nil, write: nil, delete: nil))
          c.callback_user_finder(->(id) { double("user", id: id) })
          c.handler_class("TestHandler", handler_class)
        end
      end

      before do
        allow_any_instance_of(app).to receive(:config).and_return(config_instance)
        allow_any_instance_of(app).to receive(:resolve_user_session).and_return(double("session", user: double("user", id: "U123")))
        callback = SlackBot::Callback.create(
          class_name: "TestHandler",
          user: double("user", id: "U123"),
          config: config_instance
        )
        allow(SlackBot::Callback).to receive(:find).and_return(callback)
      end

      it "handles block_actions" do
        timestamp = Time.now.to_i
        payload = {
          type: "block_actions",
          user: {id: "U123", team_id: "T123"},
          view: {callback_id: "callback_123"}
        }.to_json
        body = {payload: payload}.to_json
        post "/interactions", body, slack_headers(timestamp, body)
        expect([200, 201]).to include(last_response.status)
      end

      it "handles view_submission" do
        timestamp = Time.now.to_i
        payload = {
          type: "view_submission",
          user: {id: "U123", team_id: "T123"},
          view: {callback_id: "callback_123"}
        }.to_json
        body = {payload: payload}.to_json
        post "/interactions", body, slack_headers(timestamp, body)
        expect([200, 201]).to include(last_response.status)
      end

      it "raises error for unknown action type" do
        timestamp = Time.now.to_i
        payload = {
          type: "unknown_action",
          user: {id: "U123", team_id: "T123"},
          view: {callback_id: "callback_123"}
        }.to_json
        body = {payload: payload}.to_json
        post "/interactions", body, slack_headers(timestamp, body)
        expect(last_response.status).to eq(200)
      end

      it "raises error for invalid JSON payload" do
        timestamp = Time.now.to_i
        body = {payload: "invalid json"}.to_json
        post "/interactions", body, slack_headers(timestamp, body)
        expect(last_response.status).to eq(200)
      end

      it "returns false when callback is not found" do
        allow(SlackBot::Callback).to receive(:find).and_return(nil)
        timestamp = Time.now.to_i
        payload = {
          type: "block_actions",
          user: {id: "U123", team_id: "T123"},
          view: {callback_id: "callback_123"}
        }.to_json
        body = {payload: payload}.to_json
        post "/interactions", body, slack_headers(timestamp, body)
        expect(last_response.status).to eq(200)
      end

      it "raises error when callback user mismatch" do
        callback = SlackBot::Callback.create(
          class_name: "TestHandler",
          user: double("user", id: "U999"),
          config: config_instance
        )
        allow(SlackBot::Callback).to receive(:find).and_return(callback)
        timestamp = Time.now.to_i
        payload = {
          type: "block_actions",
          user: {id: "U123", team_id: "T123"},
          view: {callback_id: "callback_123"}
        }.to_json
        body = {payload: payload}.to_json
        post "/interactions", body, slack_headers(timestamp, body)
        expect(last_response.status).to eq(200)
      end

      it "returns false when interaction_klass is blank" do
        handler_without_interaction = Class.new
        config_instance = SlackBot::Config.new.tap do |c|
          c.callback_storage(double("storage", read: nil, write: nil, delete: nil))
          c.callback_user_finder(->(id) { double("user", id: id) })
          c.handler_class("TestHandler", handler_without_interaction)
        end
        allow_any_instance_of(app).to receive(:config).and_return(config_instance)
        callback = SlackBot::Callback.create(
          class_name: "TestHandler",
          user: double("user", id: "U123"),
          config: config_instance
        )
        allow(callback).to receive(:handler_class).and_return(handler_without_interaction)
        allow(SlackBot::Callback).to receive(:find).and_return(callback)
        timestamp = Time.now.to_i
        payload = {
          type: "block_actions",
          user: {id: "U123", team_id: "T123"},
          view: {callback_id: "callback_123"}
        }.to_json
        body = {payload: payload}.to_json
        post "/interactions", body, slack_headers(timestamp, body)
        expect(last_response.status).to eq(200)
        expect(last_response.body).to eq('""')
      end
    end
  end

  describe "commands endpoint" do
    before do
      ENV["SLACK_TEAM_ID"] = "T123"
      allow_any_instance_of(command_class).to receive(:only_direct_message?).and_return(false)
    end

    it "handles slash command" do
      timestamp = Time.now.to_i
      body = '{"command":"/test","text":"start","team_id":"T123"}'
      post "/commands/test", body, slack_headers(timestamp, body)
      expect([200, 201]).to include(last_response.status)
      expect(JSON.parse(last_response.body)["text"]).to eq("Hello")
    end

    it "returns false when command returns nil" do
      allow_any_instance_of(command_class).to receive(:call).and_return(nil)
      timestamp = Time.now.to_i
      body = '{"command":"/test","text":"start","team_id":"T123"}'
      post "/commands/test", body, slack_headers(timestamp, body)
      expect(last_response.status).to eq(200)
      expect(last_response.body).to eq('""')
    end

    it "raises error when command is not implemented" do
      timestamp = Time.now.to_i
      body = '{"command":"/unknown","text":"","team_id":"T123"}'
      post "/commands/unknown", body, slack_headers(timestamp, body)
      expect(last_response.status).to eq(200)
    end

    it "verifies slack team when only_slack_team? is true" do
      allow_any_instance_of(command_class).to receive(:only_slack_team?).and_return(true)
      timestamp = Time.now.to_i
      body = '{"command":"/test","text":"start","team_id":"T123"}'
      post "/commands/test", body, slack_headers(timestamp, body)
      expect([200, 201]).to include(last_response.status)
    end

    it "verifies direct message channel when only_direct_message? is true" do
      allow_any_instance_of(command_class).to receive(:only_direct_message?).and_return(true)
      timestamp = Time.now.to_i
      body = '{"command":"/test","text":"start","channel_name":"directmessage"}'
      post "/commands/test", body, slack_headers(timestamp, body)
      expect(last_response.status).to eq(200)
    end

    it "verifies current user when only_user? is true" do
      allow_any_instance_of(command_class).to receive(:only_user?).and_return(true)
      timestamp = Time.now.to_i
      body = '{"command":"/test","text":"start"}'
      post "/commands/test", body, slack_headers(timestamp, body)
      expect(last_response.status).to eq(200)
    end
  end

  describe "menu_options endpoint" do
    it "handles menu options request" do
      timestamp = Time.now.to_i
      body = ""
      get "/menu_options", {action_id: "test_action"}, slack_headers(timestamp, body)
      expect(last_response.status).to eq(200)
      expect(JSON.parse(last_response.body)["options"]).to be_present
    end

    it "returns false when menu options returns nil" do
      allow_any_instance_of(menu_options_class).to receive(:call).and_return(nil)
      timestamp = Time.now.to_i
      body = ""
      get "/menu_options", {action_id: "test_action"}, slack_headers(timestamp, body)
      expect(last_response.status).to eq(200)
      expect(last_response.body).to eq('""')
    end

    it "raises error when menu options is not implemented" do
      timestamp = Time.now.to_i
      body = ""
      get "/menu_options", {action_id: "unknown"}, slack_headers(timestamp, body)
      expect(last_response.status).to eq(200)
    end
  end

  describe "events endpoint" do
    it "handles url_verification" do
      timestamp = Time.now.to_i
      body = '{"type":"url_verification","challenge":"test_challenge"}'
      post "/events", body, slack_headers(timestamp, body)
      expect(JSON.parse(last_response.body)["challenge"]).to eq("test_challenge")
    end

    it "handles event_callback" do
      ENV["SLACK_TEAM_ID"] = "T123"
      timestamp = Time.now.to_i
      body = '{"type":"event_callback","team_id":"T123","event":{"type":"message"}}'
      post "/events", body, slack_headers(timestamp, body)
      expect([200, 201]).to include(last_response.status)
    end

    it "raises error for unknown event type" do
      timestamp = Time.now.to_i
      body = '{"type":"unknown_event"}'
      post "/events", body, slack_headers(timestamp, body)
      expect(last_response.status).to eq(200)
      expect(JSON.parse(last_response.body)["error"]).to include("Unknown action type")
    end

    it "returns false when result is blank" do
      ENV["SLACK_TEAM_ID"] = "T123"
      allow_any_instance_of(event_class).to receive(:call).and_return(nil)
      timestamp = Time.now.to_i
      body = '{"type":"event_callback","team_id":"T123","event":{"type":"message"}}'
      post "/events", body, slack_headers(timestamp, body)
      expect(last_response.status).to eq(200)
      expect(last_response.body).to eq('""')
    end

  end
end

