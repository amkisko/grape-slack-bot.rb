require "spec_helper"

describe SlackBot::Interaction do
  subject { described_class.new(current_user: current_user, params: params, callback: callback, config: config) }

  let(:current_user) { double("current_user") }
  let(:params) { {} }
  let(:callback) { instance_double(SlackBot::Callback, id: "test-callback-id", args: instance_double(SlackBot::Args)) }
  let(:config) { instance_double(SlackBot::Config) }

  before do
    if callback
      allow(callback).to receive(:view_id=).and_return(nil)
      allow(callback).to receive(:save).and_return(nil)
    end
  end

  it "initializes" do
    expect(subject.current_user).to eq(current_user)
    expect(subject.params).to eq(params)
    expect(subject.callback).to eq(callback)
    expect(subject.config).to eq(config)
  end

  describe ".open_modal" do
    subject(:open_modal) { described_class.open_modal(callback: callback, trigger_id: trigger_id, view: view) }

    let(:trigger_id) { "trigger_id" }
    let(:view) { {} }
    let(:response) { instance_double(SlackBot::ApiResponse, ok?: true, data: {"view" => {"id" => "view_id"}}) }

    before do
      allow(SlackBot::ApiClient).to receive(:new).and_return(instance_double(SlackBot::ApiClient, views_open: response))
    end

    it "opens modal" do
      expect(open_modal).to eq(SlackBot::Interaction::SlackViewsReply.new(callback&.id, "view_id"))
    end

    context "when callback is nil" do
      let(:callback) { nil }

      it "opens modal without callback_id" do
        expect(open_modal).to eq(SlackBot::Interaction::SlackViewsReply.new(nil, "view_id"))
      end
    end

    context "when view_id is not in response" do
      let(:response) { instance_double(SlackBot::ApiResponse, ok?: true, data: {}) }

      it "returns reply with nil view_id" do
        expect(open_modal).to eq(SlackBot::Interaction::SlackViewsReply.new(callback&.id, nil))
      end

      it "does not update callback when view_id is nil" do
        expect(callback).not_to receive(:view_id=)
        expect(callback).not_to receive(:save)
        open_modal
      end
    end

    context "when callback is present but view_id is nil" do
      let(:response) { instance_double(SlackBot::ApiResponse, ok?: true, data: {"view" => {}}) }

      it "does not update callback" do
        expect(callback).not_to receive(:view_id=)
        expect(callback).not_to receive(:save)
        open_modal
      end
    end

    context "when response is not ok" do
      let(:response) { instance_double(SlackBot::ApiResponse, ok?: false, error: "error", data: {"view" => {"id" => "view_id"}}) }

      it "raises error" do
        expect { open_modal }.to raise_error(SlackBot::Errors::OpenModalError)
      end
    end
  end

  describe ".update_modal" do
    subject(:update_modal) { described_class.update_modal(callback: callback, view_id: view_id, view: view) }

    let(:view_id) { "view_id" }
    let(:view) { {} }
    let(:response) { instance_double(SlackBot::ApiResponse, ok?: true, data: {"view" => {"id" => "view_id"}}) }

    before do
      allow(SlackBot::ApiClient).to receive(:new).and_return(instance_double(SlackBot::ApiClient, views_update: response))
    end

    it "updates modal" do
      expect(update_modal).to eq(SlackBot::Interaction::SlackViewsReply.new(callback&.id, "view_id"))
    end

    context "when callback is nil" do
      let(:callback) { nil }

      it "updates modal without callback_id" do
        expect(update_modal).to eq(SlackBot::Interaction::SlackViewsReply.new(nil, "view_id"))
      end
    end

    context "when view_id is not in response" do
      let(:response) { instance_double(SlackBot::ApiResponse, ok?: true, data: {}) }

      it "returns reply with nil view_id" do
        expect(update_modal).to eq(SlackBot::Interaction::SlackViewsReply.new(callback&.id, nil))
      end

      it "does not update callback when view_id is nil" do
        expect(callback).not_to receive(:view_id=)
        expect(callback).not_to receive(:save)
        update_modal
      end
    end

    context "when callback is present but view_id is nil" do
      let(:response) { instance_double(SlackBot::ApiResponse, ok?: true, data: {"view" => {}}) }

      it "does not update callback" do
        expect(callback).not_to receive(:view_id=)
        expect(callback).not_to receive(:save)
        update_modal
      end
    end

    context "when response is not ok" do
      let(:response) { instance_double(SlackBot::ApiResponse, ok?: false, error: "error", data: {"view" => {"id" => "view_id"}}) }

      it "raises error" do
        expect { update_modal }.to raise_error(SlackBot::Errors::UpdateModalError)
      end
    end
  end

  describe ".publish_view" do
    subject(:publish_view) { described_class.publish_view(callback: callback, metadata: metadata, user_id: user_id, view: view) }

    let(:user_id) { "user_id" }
    let(:metadata) { "metadata" }
    let(:view) { {} }
    let(:response) { instance_double(SlackBot::ApiResponse, ok?: true, data: {"view" => {"id" => "view_id"}}) }

    before do
      allow(SlackBot::ApiClient).to receive(:new).and_return(instance_double(SlackBot::ApiClient, views_publish: response))
    end

    it "publishes view" do
      expect(publish_view).to eq(SlackBot::Interaction::SlackViewsReply.new(callback&.id, "view_id"))
    end

    context "when callback is nil" do
      let(:callback) { nil }

      it "publishes view without callback_id" do
        expect(publish_view).to eq(SlackBot::Interaction::SlackViewsReply.new(nil, "view_id"))
      end
    end

    context "when metadata is nil" do
      let(:metadata) { nil }

      it "publishes view without metadata" do
        expect(publish_view).to eq(SlackBot::Interaction::SlackViewsReply.new(callback&.id, "view_id"))
      end
    end

    context "when view_id is not in response" do
      let(:response) { instance_double(SlackBot::ApiResponse, ok?: true, data: {}) }

      it "returns reply with nil view_id" do
        expect(publish_view).to eq(SlackBot::Interaction::SlackViewsReply.new(callback&.id, nil))
      end

      it "does not update callback when view_id is nil" do
        expect(callback).not_to receive(:view_id=)
        expect(callback).not_to receive(:save)
        publish_view
      end
    end

    context "when callback is present but view_id is nil" do
      let(:response) { instance_double(SlackBot::ApiResponse, ok?: true, data: {"view" => {}}) }

      it "does not update callback" do
        expect(callback).not_to receive(:view_id=)
        expect(callback).not_to receive(:save)
        publish_view
      end
    end

    context "when response is not ok" do
      let(:response) { instance_double(SlackBot::ApiResponse, ok?: false, error: "error", data: {"view" => {"id" => "view_id"}}) }

      it "raises error" do
        expect { publish_view }.to raise_error(SlackBot::Errors::PublishViewError)
      end
    end
  end

  describe "#call" do
    it "returns nil by default" do
      expect(subject.call).to be_nil
    end
  end

  describe "#payload" do
    let(:params) { {payload: '{"type":"block_actions","trigger_id":"trigger_123"}'} }

    it "parses JSON payload" do
      expect(subject.send(:payload)).to eq({"type" => "block_actions", "trigger_id" => "trigger_123"})
    end

    context "when payload is invalid JSON" do
      let(:params) { {payload: "invalid json"} }

      it "raises InvalidPayloadError" do
        expect { subject.send(:payload) }.to raise_error(SlackBot::Errors::InvalidPayloadError)
      end
    end
  end

  describe "#interaction_type" do
    let(:params) { {payload: '{"type":"block_actions"}'} }

    it "returns interaction type from payload" do
      expect(subject.send(:interaction_type)).to eq("block_actions")
    end
  end

  describe "#actions" do
    let(:params) { {payload: '{"actions":[{"action_id":"test"}]}'} }

    it "returns actions from payload" do
      expect(subject.send(:actions)).to eq([{"action_id" => "test"}])
    end
  end

  describe "#render_view" do
    let(:params) { {} }
    let(:view_class) { Class.new(SlackBot::View) }
    let(:view_instance) { view_class.new(current_user: current_user, params: params) }

    before do
      subject.class.view(view_class)
      allow(view_class).to receive(:new).and_return(view_instance)
      allow(view_instance).to receive(:test_view).and_return({type: "modal"})
    end

    it "renders view using view class" do
      result = subject.send(:render_view, :test_view)
      expect(result).to eq({type: "modal"})
    end
  end

  describe "#update_callback_args" do
    let(:params) { {payload: '{"actions":[{"value":"test_value"}]}'} }
    let(:callback) { instance_double(SlackBot::Callback, id: "test-callback-id", args: SlackBot::Args.new, save: true) }

    before do
      if callback
        allow(callback).to receive(:view_id=).and_return(nil)
      end
    end

    it "updates callback args from first action value" do
      subject.send(:update_callback_args)
      expect(callback.args.raw_args).to eq("test_value")
    end

    context "with block" do
      it "executes block for each action" do
        executed = []
        subject.send(:update_callback_args) do |action|
          executed << action
        end
        expect(executed.length).to eq(1)
      end
    end

    context "when callback is blank" do
      let(:callback) { nil }

      it "does nothing" do
        expect { subject.send(:update_callback_args) }.not_to raise_error
      end
    end

    context "when actions are blank" do
      let(:params) { {payload: '{"actions":[]}'} }

      it "does nothing" do
        expect { subject.send(:update_callback_args) }.not_to raise_error
      end
    end
  end

  describe "#update_modal" do
    let(:params) { {payload: '{"view":{"id":"view_123"}}'} }
    let(:view_class) { Class.new(SlackBot::View) }
    let(:view_instance) { view_class.new(current_user: current_user, params: params) }

    before do
      subject.class.view(view_class)
      allow(view_class).to receive(:new).and_return(view_instance)
      allow(view_instance).to receive(:test_view).and_return({type: "modal"})
      allow(described_class).to receive(:update_modal).and_return(
        SlackBot::Interaction::SlackViewsReply.new("callback_id", "view_id")
      )
    end

    it "updates modal using class method" do
      subject.send(:update_modal, :test_view)
      expect(described_class).to have_received(:update_modal).with(
        view_id: "view_123",
        view: {type: "modal"},
        callback: callback
      )
    end

    context "when callback is blank" do
      let(:callback) { nil }

      it "does nothing" do
        expect(described_class).not_to receive(:update_modal)
        subject.send(:update_modal, :test_view)
      end
    end
  end

  describe "#publish_view" do
    let(:params) { {payload: '{"user":{"id":"U123"}}'} }
    let(:view_class) { Class.new(SlackBot::View) }
    let(:view_instance) { view_class.new(current_user: current_user, params: params) }

    before do
      subject.class.view(view_class)
      allow(view_class).to receive(:new).and_return(view_instance)
      allow(view_instance).to receive(:test_view).and_return({type: "home"})
      allow(described_class).to receive(:publish_view).and_return(
        SlackBot::Interaction::SlackViewsReply.new("callback_id", "view_id")
      )
    end

    it "publishes view using class method" do
      subject.send(:publish_view, :test_view)
      expect(described_class).to have_received(:publish_view).with(
        callback: callback,
        metadata: nil,
        user_id: "U123",
        view: {type: "home"}
      )
    end

    context "with metadata" do
      it "passes metadata" do
        subject.send(:publish_view, :test_view, metadata: {test: "data"})
        expect(described_class).to have_received(:publish_view).with(
          callback: callback,
          metadata: {test: "data"},
          user_id: "U123",
          view: {type: "home"}
        )
      end
    end
  end
end
