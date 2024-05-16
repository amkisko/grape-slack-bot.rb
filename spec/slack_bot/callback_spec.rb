require "spec_helper"

describe SlackBot::Callback do
  subject(:callback) {
    described_class.new(
      class_name: "Test",
      user: user,
      channel_id: "test_channel_id",
      payload: {test: "test"},
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
    subject(:find) { described_class.find(callback_id, user: user, config: config) }

    let(:cached_data) {
      {
        class_name: "Test",
        user_id: user.id,
        channel_id: "test_channel_id",
        payload: {test: "test"},
        args: "test"
      }
    }

    before do
      allow(callback_storage_instance).to receive(:read).with("#{SlackBot::Callback::CALLBACK_KEY_PREFIX}:u#{user.id}:#{callback_id}").and_return(cached_data)
    end

    it "returns callback" do
      expect(find).to be_a(described_class)
      expect(find.id).to eq(callback_id)
      expect(find.class_name).to eq("Test")
      expect(find.user).to eq(user)
      expect(find.channel_id).to eq("test_channel_id")
      expect(find.payload).to eq({test: "test"})
      expect(find.args).to be_a(SlackBot::Args)
    end

    context "when callback is not found" do
      let(:cached_data) { nil }

      it "returns nil" do
        expect(find).to be_nil
      end
    end
  end

  describe ".create" do
    subject(:create) {
      described_class.create(
        class_name: "Test",
        user: user,
        channel_id: "test_channel_id",
        payload: {test: "test"},
        config: config
      )
    }

    let(:cached_data) {
      {
        class_name: "Test",
        user_id: user.id,
        channel_id: "test_channel_id",
        payload: {test: "test"},
        args: "",
        view_id: nil
      }
    }

    before do
      allow_any_instance_of(described_class).to receive(:generate_id).and_return(callback_id)
      allow(callback_storage_instance).to receive(:write).with("#{SlackBot::Callback::CALLBACK_KEY_PREFIX}:u#{user.id}:#{callback_id}", cached_data, expires_in: SlackBot::Callback::CALLBACK_RECORD_EXPIRES_IN).and_return(cached_data)
      allow(callback_storage_instance).to receive(:read).with("#{SlackBot::Callback::CALLBACK_KEY_PREFIX}:u#{user.id}:#{callback_id}").and_return(cached_data)
    end

    it "creates callback" do
      expect(create).to be_a(described_class)
      expect(create.id).to be_present
      expect(create.class_name).to eq("Test")
      expect(create.user).to eq(user)
      expect(create.channel_id).to eq("test_channel_id")
      expect(create.payload).to eq({test: "test"})
      expect(create.args).to be_a(SlackBot::Args)
    end
  end

  describe ".find_or_create" do
    subject(:find_or_create) {
      described_class.find_or_create(
        id: callback_id,
        class_name: "Test",
        user: user,
        channel_id: "test_channel_id",
        payload: {test: "test"},
        config: config
      )
    }

    let(:cached_data) {
      {
        class_name: "Test",
        user_id: user.id,
        channel_id: "test_channel_id",
        payload: {test: "test"},
        args: ""
      }
    }

    before do
      allow_any_instance_of(described_class).to receive(:generate_id).and_return(callback_id)
      allow(callback_storage_instance).to receive(:write).with("#{SlackBot::Callback::CALLBACK_KEY_PREFIX}:u#{user.id}:#{callback_id}", cached_data, expires_in: SlackBot::Callback::CALLBACK_RECORD_EXPIRES_IN).and_return(cached_data)
      allow(callback_storage_instance).to receive(:read).with("#{SlackBot::Callback::CALLBACK_KEY_PREFIX}:u#{user.id}:#{callback_id}").and_return(cached_data)
    end

    it "finds or creates callback" do
      expect(find_or_create).to be_a(described_class)
      expect(find_or_create.id).to eq(callback_id)
      expect(find_or_create.class_name).to eq("Test")
      expect(find_or_create.user).to eq(user)
      expect(find_or_create.channel_id).to eq("test_channel_id")
      expect(find_or_create.payload).to eq({test: "test"})
      expect(find_or_create.args).to be_a(SlackBot::Args)
    end
  end
end
