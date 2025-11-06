require "spec_helper"

describe SlackBot::View do
  let(:current_user) { double(:user, id: 1) }
  let(:params) { {command: "/test"} }
  let(:args) { instance_double(SlackBot::Args) }
  let(:context) { {title: "Test Title", text: "Test Text"} }
  let(:config) { instance_double(SlackBot::Config) }

  subject(:view) do
    described_class.new(
      current_user: current_user,
      params: params,
      args: args,
      context: context,
      config: config
    )
  end

  describe "#initialize" do
    it "sets current_user" do
      expect(view.current_user).to eq(current_user)
    end

    it "sets params" do
      expect(view.params).to eq(params)
    end

    it "sets args" do
      expect(view.args).to eq(args)
    end

    it "sets context with indifferent access" do
      expect(view.context).to be_a(ActiveSupport::HashWithIndifferentAccess)
      expect(view.context[:title]).to eq("Test Title")
      expect(view.context["title"]).to eq("Test Title")
    end

    it "sets config" do
      expect(view.config).to eq(config)
    end

    context "when context is nil" do
      subject(:view) do
        described_class.new(
          current_user: current_user,
          params: params,
          context: nil
        )
      end

      it "sets context to nil" do
        expect(view.context).to be_nil
      end
    end

    context "when context is not a hash" do
      subject(:view) do
        described_class.new(
          current_user: current_user,
          params: params,
          context: "not a hash"
        )
      end

      it "sets context to nil" do
        expect(view.context).to be_nil
      end
    end

    context "when config is not provided" do
      subject(:view) do
        described_class.new(
          current_user: current_user,
          params: params
        )
      end

      it "uses default config" do
        expect(view.config).to be_a(SlackBot::Config)
      end
    end
  end

  describe "#text_modal" do
    it "returns a text modal structure" do
      result = view.text_modal
      expect(result).to eq({
        title: {
          type: "plain_text",
          text: "Test Title"
        },
        blocks: [
          {type: "section", text: {type: "mrkdwn", text: "Test Text"}}
        ]
      })
    end

    context "when context is nil" do
      let(:context) { nil }

      it "handles nil context gracefully" do
        expect { view.text_modal }.not_to raise_error
      end
    end
  end

  describe "method_missing" do
    it "returns context value when key exists" do
      expect(view.title).to eq("Test Title")
      expect(view.text).to eq("Test Text")
    end

    it "raises NoMethodError when key doesn't exist" do
      expect { view.nonexistent }.to raise_error(NoMethodError)
    end
  end

  describe ".pager_klass" do
    after do
      # Clean up any custom pager that might have been set
      if SlackBot::View.singleton_class.instance_methods(false).include?(:pager_klass)
        SlackBot::View.singleton_class.remove_method(:pager_klass) if SlackBot::View.singleton_class.instance_method(:pager_klass).owner != SlackBot::Concerns::PagerKlass::ClassMethods
      end
    end

    it "returns SlackBot::Pager by default" do
      expect(view.class.pager_klass).to eq(SlackBot::Pager)
    end

    context "when pager is set" do
      let(:custom_pager_class) { Class.new }

      before do
        view.class.pager(custom_pager_class)
      end

      after do
        # Clean up the custom pager
        if SlackBot::View.singleton_class.instance_methods(false).include?(:pager_klass)
          SlackBot::View.singleton_class.remove_method(:pager_klass)
        end
      end

      it "returns the custom pager class" do
        expect(view.class.pager_klass).to eq(custom_pager_class)
      end
    end
  end

  describe "#paginate" do
    let(:cursor) { double("cursor", count: 0) }
    let(:real_args) { SlackBot::Args.new }
    let(:test_view) do
      described_class.new(
        current_user: current_user,
        params: params,
        args: real_args,
        context: context,
        config: config
      )
    end

    before do
      # Ensure we're using the default pager
      if SlackBot::View.singleton_class.instance_methods(false).include?(:pager_klass)
        SlackBot::View.singleton_class.remove_method(:pager_klass) if SlackBot::View.singleton_class.instance_method(:pager_klass).owner != SlackBot::Concerns::PagerKlass::ClassMethods
      end
    end

    it "creates pager with cursor and args" do
      result = test_view.send(:paginate, cursor)
      expect(result).to be_a(SlackBot::Pager)
      expect(result.source_cursor).to eq(cursor)
      expect(result.args).to eq(real_args)
    end
  end

  describe "#divider_block" do
    it "returns divider block" do
      result = view.send(:divider_block)
      expect(result).to eq({type: "divider"})
    end
  end

  describe "#current_date" do
    it "returns current date" do
      result = view.send(:current_date)
      expect(result).to eq(Date.current)
    end
  end

  describe "#command" do
    let(:params) { {command: "/test"} }

    it "returns command from params" do
      result = view.send(:command)
      expect(result).to eq("/test")
    end
  end
end
