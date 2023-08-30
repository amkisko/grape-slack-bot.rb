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
      let(:data) { { class_name: "Test", method_name: "test", user_id: 1, channel_id: "test_channel_id", extra: { test: "test" }, args: "" } }

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

    context "when callback is not found" do
      let(:data) { nil }

      it "returns nil" do
        expect(find).to eq(nil)
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
    subject(:reload) { callback.reload }
    let(:callback) {
      described_class.new(id: "test_callback_id", config: config)
    }
    let(:data) {
      {
        class_name: "Test",
        method_name: "test",
        user_id: 1,
        channel_id: "test_channel_id",
        extra: { test: "test" },
        args: ""
      }
    }

    before do
      allow(callback_storage_instance).to receive(:read).with("slack-bot-callback:test_callback_id").and_return(data)
    end

    it "returns callback" do
      expect(reload).to be_a(described_class)
      expect(reload.id).to eq("test_callback_id")
      expect(reload.class_name).to eq("Test")
      expect(reload.user).to eq(user)
      expect(reload.user_id).to eq(1)
      expect(reload.channel_id).to eq("test_channel_id")
      expect(reload.method_name).to eq("test")
      expect(reload.extra).to eq({ test: "test" })
    end

    context "when callback is not found" do
      let(:data) { nil }

      it "raises error" do
        expect { reload }.to raise_error(SlackBot::Errors::CallbackNotFound)
      end
    end
  end

  describe "#save" do
    subject(:save) { callback.save }
    let(:callback) {
      described_class.new(
        class_name: "Test",
        method_name: "test",
        user: user,
        channel_id: "test_channel_id",
        extra: { test: "test" },
        config: config
      )
    }

    before do
      allow_any_instance_of(described_class).to receive(:generate_id).and_return("test_callback_id")
      allow(callback_storage_instance).to receive(:write).with("slack-bot-callback:test_callback_id", {
        args: "",
        class_name: "Test",
        method_name: "test",
        user_id: 1,
        channel_id: "test_channel_id",
        extra: { test: "test" }
      }, expires_in: 1.hour)
    end

    it "returns callback" do
      expect { save }.not_to raise_error
      expect(callback).to be_a(described_class)
      expect(callback.id).to eq("test_callback_id")
      expect(callback.args).to be_a(SlackBot::Args)
    end
  end

  describe "#update" do
    subject(:update) { callback.update(payload) }
    let(:callback) {
      described_class.new(
        id: "test_callback_id",
        class_name: "Test",
        method_name: "test",
        user: user,
        channel_id: "test_channel_id",
        extra: { test: "test" },
        config: config
      )
    }

    before do
      allow(callback_storage_instance).to receive(:write).with("slack-bot-callback:test_callback_id", {
        args: "",
        class_name: "Test",
        method_name: "test",
        user_id: 1,
        channel_id: "test_channel_id",
        extra: { test: "test" },
        test: "test"
      }, expires_in: 1.hour)
    end

    let(:payload) { { test: "test" } }

    it "returns callback" do
      expect { update }.not_to raise_error
      expect(callback).to be_a(described_class)
      expect(callback.id).to eq("test_callback_id")
      expect(callback.args).to be_a(SlackBot::Args)
    end
  end

  describe "#destroy" do

  end

  describe "#user" do

  end

  describe "#handler_class" do

  end
end
