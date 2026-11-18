describe SlackBot::Schema::Responses do
  include_context "with signed Slack requests"

  let(:storage) do
    Class.new do
      def initialize
        @records = {}
      end

      def read(key)
        @records[key]
      end

      def write(key, value, expires_in:)
        @records[key] = value.dup
      end
    end.new
  end

  let(:view_class) do
    Class.new(SlackBot::View) do
      def panel
        {title: {type: "plain_text", text: "Task"}, blocks: [], notify_on_close: true}
      end

      def home
        {type: "home", blocks: []}
      end

      def blocks
        [{type: "divider"}]
      end
    end
  end

  before do
    config.callback_storage(storage)
    config.user_session_resolver(->(_team, _id) { Struct.new(:user).new(user) })
    allow(SlackBot::Interaction).to receive(:api_client).and_return(SlackBot::ApiClient.new(authorization_token: "test_views"))
  end

  def configure_shortcut(submission, closed)
    view_ref = view_class
    stub_const("TaskShortcut", Class.new(SlackBot::Schema::Shortcut) do
      view view_ref
      view_submission submission
      view_closed closed if closed
      respond_with open_modal: :panel
    end)
    config.use(Class.new(SlackBot::Schema) { shortcut :task, TaskShortcut })
  end

  def open_shortcut
    opened_view = nil
    stub_request(:post, "https://slack.com/api/views.open").to_return do |request|
      opened_view = JSON.parse(request.body).fetch("view")
      {status: 200, body: '{"ok":true,"view":{"id":"V1"}}'}
    end
    send_payload("shortcut", callback_id: "task", trigger_id: "trigger")
    expect(last_response).to have_attributes(status: 200, body: "")
    opened_view
  end

  it "routes an opened modal's submissions and closures via separate handlers" do
    submission = Class.new(SlackBot::Schema::ViewSubmission) do
      respond_with response_action: :clear

      def resolve
        return {errors: {"title" => "Required"}} if view_state(:title, :text).to_s.empty?

        nil
      end
    end
    closed = Class.new(SlackBot::Schema::ViewClosed) do
      def resolve
        {closed: payload["is_cleared"]}
      end
    end
    configure_shortcut(submission, closed)
    modal = open_shortcut
    expect(modal["notify_on_close"]).to be(true)

    send_payload("view_submission", view: modal.merge("id" => "V1"))
    expect(last_response.status).to eq(200)
    expect(JSON.parse(last_response.body)).to eq("response_action" => "errors", "errors" => {"title" => "Required"})

    state = {values: {title: {text: {type: "plain_text_input", value: "Next"}}}}
    send_payload("view_submission", view: modal.merge("id" => "V1", "state" => state))
    expect(JSON.parse(last_response.body)).to eq("response_action" => "clear")

    send_payload("view_closed", view: {id: "V1", type: "modal"}, is_cleared: true)
    expect(JSON.parse(last_response.body)).to eq("closed" => true)
  end

  %i[update push].each do |operation|
    it "returns the #{operation} submission response and preserves routing from its rendered view" do
      view_ref = view_class
      submit = Class.new(SlackBot::Schema::ViewSubmission) do
        view view_ref
        respond_with response_action: operation, view: :panel
      end
      configure_shortcut(submit, nil)
      modal = open_shortcut

      send_payload("view_submission", view: modal.merge("id" => "V1"))

      expect(last_response.status).to eq(200)
      result = JSON.parse(last_response.body)
      expect(result["response_action"]).to eq(operation.to_s)
      next_view = result.fetch("view")
      expect(next_view["type"]).to eq("modal")
      expect(next_view["callback_id"] == modal["callback_id"]).to eq(operation == :update)
      send_payload("view_submission", view: next_view.merge("id" => "V2"))
      expect(JSON.parse(last_response.body)["response_action"]).to eq(operation.to_s)
    end
  end

  it "opens a modal from a message shortcut without a scoped callback" do
    view_ref = view_class
    handler = Class.new(SlackBot::Schema::MessageAction) do
      view view_ref
      respond_with open_modal: :panel
    end
    config.use(Class.new(SlackBot::Schema) { message_action :task, handler })
    request = stub_request(:post, "https://slack.com/api/views.open").with do |incoming|
      JSON.parse(incoming.body).fetch("trigger_id") == "message-trigger"
    end.to_return(status: 200, body: '{"ok":true}')

    send_payload("message_action", callback_id: "task", trigger_id: "message-trigger")

    expect(last_response.status).to eq(200)
    expect(last_response.body).to be_empty
    expect(request).to have_been_requested
  end

  it "sends a response_url message with rendered blocks and acknowledges the interaction" do
    view_ref = view_class
    handler = Class.new(SlackBot::Schema::MessageAction) do
      view view_ref
      respond_with response_url: :in_channel, replace_original: true, text: "Saved", blocks: :blocks
    end
    config.use(Class.new(SlackBot::Schema) { message_action :task, handler })
    url = "https://hooks.slack.com/app-actions/test/fixture/path"
    request = stub_request(:post, url).with do |incoming|
      JSON.parse(incoming.body) == {
        "text" => "Saved", "response_type" => "in_channel", "blocks" => [{"type" => "divider"}], "replace_original" => true
      }
    end.to_return(status: 200, body: "ok")

    send_payload("message_actions", callback_id: "task", response_url: url)

    expect(last_response.status).to eq(200)
    expect(last_response.body).to be_empty
    expect(request).to have_been_requested
  end

  it "passes the Slack view hash to views.update and forwards push and publish requests" do
    view_ref = view_class
    action = Class.new(SlackBot::Schema::BlockActions) do
      view view_ref
      respond_with update_modal: :panel
    end
    push = Class.new(SlackBot::Schema::BlockActions) do
      view view_ref
      respond_with push_modal: :panel
    end
    event = Class.new(SlackBot::Schema::Event) do
      view view_ref
      respond_with publish_view: :home
    end
    stub_const("ActionShortcut", Class.new(SlackBot::Schema::Shortcut) do
      view view_ref
      block_actions action
      respond_with open_modal: :panel
    end)
    config.use(Class.new(SlackBot::Schema) do
      shortcut :task, ActionShortcut
      block_actions :push, push
      event(:app_home_opened, event)
    end)
    modal = open_shortcut
    update_request = stub_request(:post, "https://slack.com/api/views.update").with do |incoming|
      body = JSON.parse(incoming.body)
      body["view_id"] == "V1" && body["hash"] == "revision-1" && body.dig("view", "callback_id") == modal["callback_id"]
    end.to_return(status: 200, body: '{"ok":true}')
    push_request = stub_request(:post, "https://slack.com/api/views.push").with do |incoming|
      JSON.parse(incoming.body).fetch("trigger_id") == "push-trigger"
    end.to_return(status: 200, body: '{"ok":true}')
    publish_request = stub_request(:post, "https://slack.com/api/views.publish").with do |incoming|
      body = JSON.parse(incoming.body)
      body["user_id"] == "U1" && body.dig("view", "type") == "home"
    end.to_return(status: 200, body: '{"ok":true}')

    send_payload("block_actions", view: modal.merge("id" => "V1", "hash" => "revision-1"))
    expect(last_response.body).to be_empty
    expect(update_request).to have_been_requested
    send_payload("block_actions", trigger_id: "push-trigger", actions: [{action_id: "push"}])
    expect(last_response.body).to be_empty
    expect(push_request).to have_been_requested

    body = JSON.generate(type: "event_callback", team_id: "T1", event: {type: "app_home_opened", user: "U1"})
    post "/events", body, signed_headers(body, "application/json")
    expect(last_response.body).to be_empty
    expect(publish_request).to have_been_requested
  end

  it "uses a submission's Slack response URL for ephemeral replies" do
    submit = Class.new(SlackBot::Schema::ViewSubmission) do
      respond_with response_url: :ephemeral, text: "Received"
    end
    configure_shortcut(submit, nil)
    modal = open_shortcut
    url = "https://hooks.slack.com/app/test/fixture/path"
    request = stub_request(:post, url).with(body: JSON.generate(text: "Received", response_type: "ephemeral"))
      .to_return(status: 200, body: "ok")

    urls = [{block_id: "channel", action_id: "target", response_url: url}]
    send_payload("view_submission", view: modal.merge("response_urls" => urls))

    expect(last_response.status).to eq(200)
    expect(last_response.body).to be_empty
    expect(request).to have_been_requested
  end

  it "leaves Slack unchanged when the scoped callback cannot be stored" do
    submit = Class.new(SlackBot::Schema::ViewSubmission)
    configure_shortcut(submit, nil)
    allow(storage).to receive(:write).and_return(false)

    send_payload("shortcut", callback_id: "task", trigger_id: "trigger")

    expect(JSON.parse(last_response.body)["error"]).to eq("Unable to store Slack callback")
  end

  it "acknowledges a halted action without sending its declared reply" do
    action = Class.new(SlackBot::Schema::BlockActions) do
      action(:approve)
      respond_with response_url: :ephemeral, text: "Approved"

      def approve
        :halt
      end
    end
    config.use(Class.new(SlackBot::Schema) { block_actions :approve, action })

    send_payload("block_actions", response_url: "https://hooks.slack.com/actions/test/fixture/path",
      actions: [{action_id: "approve"}])

    expect(last_response.status).to eq(200)
    expect(last_response.body).to be_empty
  end

  it "deletes the source message without sending replacement content" do
    handler = Class.new(SlackBot::Schema::BlockActions) do
      respond_with delete_original: true
    end
    config.use(Class.new(SlackBot::Schema) { block_actions :remove, handler })
    url = "https://hooks.slack.com/actions/test/fixture/path"
    request = stub_request(:post, url).with(body: JSON.generate(delete_original: true))
      .to_return(status: 200, body: "ok")

    send_payload("block_actions", response_url: url, actions: [{action_id: "remove"}])

    expect(last_response).to have_attributes(status: 200, body: "")
    expect(request).to have_been_requested
  end
end
