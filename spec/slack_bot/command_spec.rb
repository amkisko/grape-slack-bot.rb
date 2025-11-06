require "spec_helper"

describe SlackBot::Command do
  let(:current_user) { double(:user, id: 1) }
  let(:params) { {command: "/test", text: "test args", channel_id: "C123", trigger_id: "trigger_123"} }
  let(:args) { "test args" }
  let(:config) { instance_double(SlackBot::Config) }

  subject(:command) do
    described_class.new(
      current_user: current_user,
      params: params,
      args: args,
      config: config
    )
  end

  describe "#initialize" do
    it "sets current_user" do
      expect(command.current_user).to eq(current_user)
    end

    it "sets params" do
      expect(command.params).to eq(params)
    end

    it "sets args" do
      expect(command.args).to be_a(SlackBot::Args)
      expect(command.args.raw_args).to eq(args)
    end

    it "sets config" do
      expect(command.config).to eq(config)
    end

    context "when config is not provided" do
      subject(:command) do
        described_class.new(
          current_user: current_user,
          params: params,
          args: args
        )
      end

      it "uses default config" do
        expect(command.config).to be_a(SlackBot::Config)
      end
    end
  end

  describe "#command" do
    it "returns command from params" do
      expect(command.command).to eq("/test")
    end
  end

  describe "#text" do
    it "returns text from params" do
      expect(command.text).to eq("test args")
    end
  end

  describe "#only_user?" do
    it "returns true" do
      expect(command.only_user?).to eq(true)
    end
  end

  describe "#only_direct_message?" do
    it "returns true" do
      expect(command.only_direct_message?).to eq(true)
    end
  end

  describe "#only_slack_team?" do
    it "returns true" do
      expect(command.only_slack_team?).to eq(true)
    end
  end

  describe "#render_response" do
    it "returns nil when response_type is nil" do
      expect(command.render_response).to be_nil
    end

    it "returns hash with response_type when provided" do
      result = command.render_response("ephemeral")
      expect(result).to eq({response_type: "ephemeral"})
    end

    it "merges additional kwargs" do
      result = command.render_response("ephemeral", text: "Hello")
      expect(result).to eq({response_type: "ephemeral", text: "Hello"})
    end
  end

  describe ".view_klass" do
    it "raises exception when not set" do
      expect { command.class.view_klass }.to raise_error(SlackBot::Errors::ViewClassNotImplemented)
    end

    context "when view is set" do
      let(:view_class) { Class.new }

      before do
        command.class.view(view_class)
      end

      it "returns the view class" do
        expect(command.class.view_klass).to eq(view_class)
      end
    end
  end

  describe ".interaction_klass" do
    it "raises exception when not set" do
      expect { command.class.interaction_klass }.to raise_error(SlackBot::Errors::InteractionClassNotImplemented)
    end

    context "when interaction is set" do
      let(:interaction_class) { Class.new }

      before do
        command.class.interaction(interaction_class)
      end

      it "returns the interaction class" do
        expect(command.class.interaction_klass).to eq(interaction_class)
      end
    end
  end

  describe "#render_view" do
    let(:view_class) { Class.new(SlackBot::View) }
    let(:view_instance) { view_class.new(current_user: current_user, params: params) }

    before do
      command.class.view(view_class)
      allow(view_class).to receive(:new).and_return(view_instance)
      allow(view_instance).to receive(:test_view).and_return({type: "modal"})
    end

    it "renders view using view class" do
      result = command.send(:render_view, :test_view)
      expect(result).to eq({type: "modal"})
    end
  end

  describe "#open_modal" do
    let(:view_class) { Class.new(SlackBot::View) }
    let(:view_instance) { view_class.new(current_user: current_user, params: params) }
    let(:interaction_class) { Class.new(SlackBot::Interaction) }
    let(:callback) { instance_double(SlackBot::Callback, id: "callback_id") }

    before do
      command.class.view(view_class)
      command.class.interaction(interaction_class)
      allow(view_class).to receive(:new).and_return(view_instance)
      allow(view_instance).to receive(:test_view).and_return({type: "modal"})
      allow(SlackBot::Callback).to receive(:create).and_return(callback)
      allow(interaction_class).to receive(:open_modal).and_return(
        SlackBot::Interaction::SlackViewsReply.new("callback_id", "view_id")
      )
    end

    it "opens modal using interaction class" do
      result = command.send(:open_modal, :test_view)
      expect(result).to be_nil
    end

    context "with existing callback" do
      it "uses provided callback" do
        command.send(:open_modal, :test_view, callback: callback)
        expect(interaction_class).to have_received(:open_modal).with(
          callback: callback,
          trigger_id: params[:trigger_id],
          view: {type: "modal"}
        )
      end
    end
  end
end
