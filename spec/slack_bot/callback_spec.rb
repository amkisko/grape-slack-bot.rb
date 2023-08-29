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

  end

  describe "#reload" do

  end

  describe "#save" do

  end

  describe "#update" do

  end

  describe "#destroy" do

  end

  describe "#klass" do

  end

  describe "#user" do

  end

  describe "#user_id" do

  end

  describe "#channel_id" do

  end

  describe "#method_name" do

  end
end
