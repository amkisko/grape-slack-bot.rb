require 'spec_helper'

describe SlackBot::Callback do
  subject(:callback) {
    described_class.new(
      class_name: "Test",
      method_name: "test",
      user: user,
      channel_id: "test_channel_id",
      extra: { test: "test" },
      config: config
    )
  }

  let(:config) {
    instance_double(
      SlackBot::Config,
      callback_storage_instance: callback_storage_instance,
      callback_user_finder_method: callback_user_finder_method
    )
  }
  let(:callback_storage_instance) { instance_double(SlackBot::CallbackStorage) }
  let(:callback_user_finder_method) { ->(user_id) { user } }

  let(:user) { double(:user, id: 1) }

  let(:callback_id) { "test_callback_id" }

  describe ".find" do
    subject(:find) { described_class.find(callback_id, config: config) }

    before do
      allow(callback_storage_instance).to receive(:read).with("slack-bot-callback:test_callback_id").and_return(data)
    end

    context "when callback is found" do
      let(:data) { { class_name: "Test", method_name: "test", user_id: 1, channel_id: "test_channel_id", extra: { test: "test" } } }

      it "returns callback" do
        expect(find).to be_a(described_class)
        expect(find.id).to eq(callback_id)
        expect(find.class_name).to eq("Test")
        expect(find.user).to eq(user)
        expect(find.user_id).to eq(1)
        expect(find.channel_id).to eq("test_channel_id")
        expect(find.method_name).to eq("test")
        expect(find.extra).to eq({ test: "test" })
      end
    end
  end

  describe ".create" do
    subject(:create) { described_class.create(class_name: "Test", method_name: "test", user: user, channel_id: "test_channel_id", config: config) }

    before do
      allow_any_instance_of(described_class).to receive(:generate_id).and_return("test_callback_id")
      allow(callback_storage_instance).to receive(:write).with("slack-bot-callback:test_callback_id", {
        args: "",
        class_name: "Test",
        method_name: "test",
        user_id: 1,
        channel_id: "test_channel_id",
        extra: nil
      }, expires_in: 1.hour)
    end

    let(:data) { { class_name: "Test", method_name: "test", user_id: 1, channel_id: "test_channel_id", extra: nil } }

    it "returns callback" do
      expect(create).to be_a(described_class)
      expect(create.id).to eq("test_callback_id")
      expect(create.class_name).to eq("Test")
      expect(create.user).to eq(user)
      expect(create.user_id).to eq(1)
      expect(create.channel_id).to eq("test_channel_id")
      expect(create.method_name).to eq("test")
      expect(create.extra).to eq(nil)
    end
  end

  describe "#reload" do

  end

  describe "#save" do

  end

  describe "#update" do

  end

  describe "#destroy" do

  end

  describe "#user" do

  end

  describe "#handler_class" do

  end
end
