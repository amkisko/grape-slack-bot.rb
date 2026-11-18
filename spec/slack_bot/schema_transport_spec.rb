describe SlackBot::GrapeExtension do
  include_context "with signed Slack requests"

  it "routes every shortcut spelling by its callback ID" do
    handler = Class.new(SlackBot::Interaction) do
      def call
        {kind: interaction_type, user: current_user.id}
      end
    end
    config.user_session_resolver(->(team, id) { Struct.new(:user).new(Struct.new(:id).new(id)) if team == "T1" })
    config.shortcut(:create, handler)
    config.message_action(:create, handler)

    %w[shortcut message_actions message_action].each do |type|
      send_payload(type, callback_id: "create")
      expect(last_response.status).to eq(200)
      expect(JSON.parse(last_response.body)).to eq("kind" => type, "user" => "U1")
    end
  end

  it "routes externally opened view closures through their callback ID" do
    handler = Class.new(SlackBot::Interaction) do
      def call
        {closed: payload["is_cleared"]}
      end
    end
    config.user_session_resolver(->(_team, _id) { Struct.new(:user).new(user) })
    config.view_closed(:panel, handler)

    send_payload("view_closed", view: {id: "V1", callback_id: "panel"}, is_cleared: true)

    expect(last_response.status).to eq(200)
    expect(JSON.parse(last_response.body)).to eq("closed" => true)
  end

  it "accepts signed POST suggestions and continues serving legacy GET" do
    handler = Class.new(SlackBot::MenuOptions) do
      def call
        {options: [{text: {type: "plain_text", text: params[:value]}, value: params[:value]}]}
      end
    end
    config.block_suggestion(:users, handler)

    send_payload("block_suggestion", path: "/menu_options", action_id: "users", value: "Alex")
    expect(last_response.status).to eq(200)
    expect(JSON.parse(last_response.body).dig("options", 0, "value")).to eq("Alex")

    get "/menu_options", {team_id: "T1", action_id: "users", value: "Al"}, signed_headers("")
    expect(last_response.status).to eq(200)
    expect(JSON.parse(last_response.body).dig("options", 0, "value")).to eq("Al")
  end

  it "reports non-object interaction payloads as invalid" do
    body = Rack::Utils.build_query(payload: "[]")
    post "/interactions", body, signed_headers(body)

    expect(JSON.parse(last_response.body)["error"]).to include("Invalid JSON payload")
  end

  it "does not accept a query parameter as the signed Options Load payload" do
    handler = Class.new(SlackBot::MenuOptions) do
      def call
        {options: [{value: "unexpected"}]}
      end
    end
    config.block_suggestion(:users, handler)
    payload = JSON.generate(type: "block_suggestion", action_id: "users", team: {id: "T1"})
    query = Rack::Utils.build_query(payload: payload)
    post "/menu_options?#{query}", "", signed_headers("")

    expect(JSON.parse(last_response.body)["error"]).to include("Invalid JSON payload")
  end

  it "routes App Home block actions without a scoped view through action IDs" do
    handler = Class.new(SlackBot::Interaction) do
      def call
        {home: true}
      end
    end
    config.block_action(:home, handler)

    send_payload("block_actions", view: {type: "home", callback_id: ""}, actions: [{action_id: "home"}])

    expect(JSON.parse(last_response.body)).to eq("home" => true)
  end

  it "keeps Slack query values out of development logs" do
    logger = instance_double(SlackBot::Logger, info: nil)
    allow(SlackBot::DevConsole).to receive_messages(enabled?: true, logger: logger)
    handler = Class.new(SlackBot::MenuOptions) do
      def call
        {options: []}
      end
    end
    config.menu_options(:users, handler)

    get "/menu_options", {team_id: "T1", action_id: "users", value: "private fixture"}, signed_headers("")

    expect(last_response.status).to eq(200)
    expect(logger).not_to have_received(:info).with(a_string_including("private fixture"))
  end

  it "reports malformed objects and action lists as invalid payloads" do
    [
      {team: "T1"}, {view: 123}, {actions: ["approve"]}, {actions: [{action_id: {id: "approve"}}]}
    ].each do |fields|
      send_payload("block_actions", **fields)

      expect(JSON.parse(last_response.body)["error"]).to include("Invalid Slack payload")
    end
  end

  it "requires a workspace in the verified interaction payload" do
    payload = {type: "block_suggestion", action_id: "users"}
    body = Rack::Utils.build_query(payload: JSON.generate(payload))
    post "/menu_options?team_id=T1", body, signed_headers(body)

    expect(JSON.parse(last_response.body)["error"]).to eq("Team is not authorized")
  end

  it "preserves Grape's legacy response for a block action with a body" do
    handler = Class.new(SlackBot::Interaction) do
      def call
        {handled: true}
      end
    end
    config.block_action(:approve, handler)

    send_payload("block_actions", actions: [{action_id: "approve"}])

    expect(last_response.status).to eq(201)
    expect(JSON.parse(last_response.body)).to eq("handled" => true)
  end
end
