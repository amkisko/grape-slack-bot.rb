describe SlackBot::Schema do
  include_context "with signed Slack requests"

  def send_command(text)
    body = Rack::Utils.build_query(command: "/game", text: text, team_id: "T1", user_id: "U1", channel_name: "directmessage")
    post "/commands/game", body, signed_headers(body)
  end

  it "mounts slash groups, coerces input and preserves the existing non-Schema command" do
    input = Class.new(SlackBot::Schema::InputObject) do
      argument :count, Integer, required: true
      argument :label, ->(value) { value.upcase }, default: "Game"
    end
    start = Class.new(SlackBot::Schema::SlashCommand) do
      input(input)

      def resolve(count:, label:)
        {text: "#{label}: #{count * 2}"}
      end
    end
    menu = Class.new(SlackBot::Schema::SlashCommand) do
      def resolve
        {text: "Menu"}
      end
    end
    legacy = Class.new(SlackBot::Command) do
      def call
        {text: "Legacy"}
      end
    end
    group = Class.new(SlackBot::Schema::SlashCommandGroup) do
      default_command menu
      command :"start|new", start
    end
    shared = Class.new(SlackBot::Schema) { slash_command :game, group }
    schema = Class.new(SlackBot::Schema) { mount shared }

    config.slash_command_endpoint(:legacy, legacy)
    config.use(schema)

    send_command("start|new count=7")
    expect(JSON.parse(last_response.body)).to eq("text" => "Game: 14")
    send_command("start|new count=2&label=task")
    expect(last_response.status).to eq(200)
    expect(JSON.parse(last_response.body)).to eq("text" => "TASK: 4")
    send_command("")
    expect(JSON.parse(last_response.body)).to eq("text" => "Menu")
    send_command("start|new count=nope")
    expect(JSON.parse(last_response.body)["error"]).to include("count")

    body = Rack::Utils.build_query(text: "", team_id: "T1", channel_name: "directmessage")
    post "/commands/legacy", body, signed_headers(body)
    expect(JSON.parse(last_response.body)).to eq("text" => "Legacy")
  end

  it "uses the mounted session and event configuration in the event handler" do
    event = Class.new(SlackBot::Schema::Event) do
      def resolve
        {user: current_user.id, storage: config.callback_storage!.fetch(:label)}
      end
    end
    schema = Class.new(SlackBot::Schema) do
      callback_storage({label: "mounted"})
      user_session_resolver ->(team, id) { Struct.new(:user).new(Struct.new(:id).new(id)) if team == "T1" }
      event(:app_home_opened, event)
    end
    config.mount(schema)

    body = JSON.generate(type: "event_callback", team_id: "T1", event: {type: "app_home_opened", user: "U5"})
    post "/events", body, signed_headers(body, "application/json")

    expect(JSON.parse(last_response.body)).to eq("user" => "U5", "storage" => "mounted")
  end

  it "routes matching block actions with extracted values and acknowledges unhandled actions" do
    service = Class.new do
      def initialize(users:)
        @users = users
      end

      def call
        {users: @users}
      end
    end
    actions = Class.new(SlackBot::Schema::BlockActions) do
      action :approve, args: {selected: :selected_option_value, label: ->(action) { action["value"].upcase }}

      def approve(selected:, label:)
        {selected: selected, label: label}
      end

      action :members, with: service, args: {users: :selected_users}
    end
    config.use(Class.new(SlackBot::Schema) do
      block_actions :approve, actions
      block_actions :members, actions
    end)

    send_payload("block_actions", actions: [{action_id: "approve", value: "ready", selected_option: {value: "42"}}])
    expect(JSON.parse(last_response.body)).to eq("selected" => "42", "label" => "READY")
    send_payload("block_actions", actions: [{action_id: "members", selected_users: %w[U1 U2]}])
    expect(JSON.parse(last_response.body)).to eq("users" => %w[U1 U2])
    send_payload("block_actions", actions: [])
    expect(last_response.status).to eq(200)
  end

  it "resolves typed POST and GET Options handlers" do
    options = Class.new(SlackBot::Schema::Options) do
      def resolve
        {options: [{value: value}]}
      end
    end
    config.use(Class.new(SlackBot::Schema) { options(:users, options) })

    send_payload("block_suggestion", path: "/menu_options", action_id: "users", value: "Al")
    expect(JSON.parse(last_response.body)).to eq("options" => [{"value" => "Al"}])
    get "/menu_options", {team_id: "T1", action_id: "users", value: "Ada"}, signed_headers("")
    expect(JSON.parse(last_response.body)).to eq("options" => [{"value" => "Ada"}])
  end

  it "acknowledges the event when a Schema dispatcher queues its handler" do
    jobs = []
    handler = Class.new(SlackBot::Schema::Event) do
      def resolve
        raise "Ran inline"
      end
    end
    config.use(Class.new(SlackBot::Schema) do
      user_session_resolver ->(_team, id) { Struct.new(:user).new(Struct.new(:id).new(id)) }
      event_dispatcher ->(**job) { jobs << job }
      event :app_home_opened, handler
    end)

    body = JSON.generate(type: "event_callback", team_id: "T1", event: {type: "app_home_opened", user: "U5"})
    post "/events", body, signed_headers(body, "application/json")

    expect(last_response.status).to eq(200)
    expect(last_response.body).to be_empty
    expect(jobs).to contain_exactly(include(handler: handler, current_user: have_attributes(id: "U5")))
  end
end
