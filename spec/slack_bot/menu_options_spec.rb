require "spec_helper"

describe SlackBot::MenuOptions do
  let(:current_user) { double(:user, id: 1) }
  let(:params) { {action_id: "test_action"} }
  let(:config) { instance_double(SlackBot::Config) }

  subject(:menu_options) do
    described_class.new(
      current_user: current_user,
      params: params,
      config: config
    )
  end

  describe "#initialize" do
    it "sets current_user" do
      expect(menu_options.current_user).to eq(current_user)
    end

    it "sets params" do
      expect(menu_options.params).to eq(params)
    end

    it "sets config" do
      expect(menu_options.config).to eq(config)
    end

    context "when config is not provided" do
      subject(:menu_options) do
        described_class.new(
          current_user: current_user,
          params: params
        )
      end

      it "uses default config" do
        expect(menu_options.config).to be_a(SlackBot::Config)
      end
    end
  end

  describe "#call" do
    it "returns nil by default" do
      expect(menu_options.call).to be_nil
    end
  end
end
