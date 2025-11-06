require "spec_helper"

describe SlackBot::Event do
  let(:current_user) { double(:current_user) }
  let(:params) { double(:params) }
  let(:callback) { instance_double(SlackBot::Callback, args: instance_double(SlackBot::Args)) }
  let(:config) { instance_double(SlackBot::Config) }

  subject do
    described_class.new(
      current_user: current_user,
      params: params,
      callback: callback,
      config: config
    )
  end

  describe ".view_klass" do
    it "raises exception" do
      expect { subject.class.view_klass }.to raise_error(SlackBot::Errors::ViewClassNotImplemented)
    end

    context "when view is called" do
      before do
        subject.class.view :view_name
      end
      it "returns view_name" do
        expect(subject.class.view_klass).to eq(:view_name)
      end
    end
  end

  describe ".interaction_klass" do
    it "raises exception" do
      expect { subject.class.interaction_klass }.to raise_error(SlackBot::Errors::InteractionClassNotImplemented)
    end
    context "when interaction is called" do
      before do
        subject.class.interaction :interaction_name
      end
      it "returns interaction_name" do
        expect(subject.class.interaction_klass).to eq(:interaction_name)
      end
    end
  end

  describe "#initialize" do
    it "sets current_user" do
      expect(subject.current_user).to eq(current_user)
    end

    it "sets params" do
      expect(subject.params).to eq(params)
    end

    it "sets callback" do
      expect(subject.callback).to eq(callback)
    end

    it "sets config" do
      expect(subject.config).to eq(config)
    end
  end

  describe "#call" do
    it "returns nil" do
      expect(subject.call).to eq(nil)
    end
  end

  describe "#publish_view" do
    let(:params) { {"event" => {"user" => "U123", "type" => "app_home_opened"}} }
    let(:view_class) { Class.new(SlackBot::View) }
    let(:view_instance) { view_class.new(current_user: current_user, params: params) }

    before do
      subject.class.view(view_class)
      allow(view_class).to receive(:new).and_return(view_instance)
      allow(view_instance).to receive(:index_view).and_return({type: "home", blocks: []})
      allow(SlackBot::Interaction).to receive(:publish_view).and_return(
        SlackBot::Interaction::SlackViewsReply.new("callback_id", "view_id")
      )
    end

    it "publishes view using Interaction.publish_view" do
      expect(SlackBot::Interaction).to receive(:publish_view).with(
        callback: callback,
        metadata: nil,
        user_id: "U123",
        view: {type: "home", blocks: []}
      )
      subject.send(:publish_view, :index_view)
    end

    it "returns nil" do
      expect(subject.send(:publish_view, :index_view)).to be_nil
    end
  end

  describe "#event_type" do
    let(:params) { {"event" => {"type" => "app_home_opened"}} }

    it "returns event type from params" do
      expect(subject.send(:event_type)).to eq("app_home_opened")
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

    it "passes context to view" do
      expect(view_class).to receive(:new).with(
        args: callback&.args,
        current_user: current_user,
        params: params,
        context: {test: "value"},
        config: config
      ).and_return(view_instance)
      subject.send(:render_view, :test_view, context: {test: "value"})
    end
  end
end
