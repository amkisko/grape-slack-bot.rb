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

    context "when id is blank" do
      let(:callback_id) { nil }

      it "returns nil" do
        expect(find).to be_nil
      end
    end
  end

  describe ".find_by_view_id" do
    subject(:find_by_view_id) { described_class.find_by_view_id("view_123", user: user, config: config) }

    before do
      allow(callback_storage_instance).to receive(:read).with("#{SlackBot::Callback::CALLBACK_KEY_PREFIX}:u#{user.id}:view_123").and_return("callback_id_123")
      allow(described_class).to receive(:find).with("callback_id_123", user: user, config: config).and_return(callback)
    end

    it "finds callback by view_id" do
      expect(find_by_view_id).to eq(callback)
    end

    context "when callback_id is not found" do
      before do
        allow(callback_storage_instance).to receive(:read).with("#{SlackBot::Callback::CALLBACK_KEY_PREFIX}:u#{user.id}:view_123").and_return(nil)
      end

      it "returns nil" do
        expect(find_by_view_id).to be_nil
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

    context "when callback already exists" do
      before do
        allow(described_class).to receive(:find).with(callback_id, user: user, config: config).and_return(callback)
      end

      it "returns existing callback" do
        expect(find_or_create).to eq(callback)
      end
    end
  end

  describe "#reload" do
    let(:cached_data) {
      {
        class_name: "Test",
        user_id: user.id,
        channel_id: "test_channel_id",
        payload: {test: "test"},
        args: "foo=bar"
      }
    }

    before do
      callback.id = callback_id
      allow(callback_storage_instance).to receive(:read).with("#{SlackBot::Callback::CALLBACK_KEY_PREFIX}:u#{user.id}:#{callback_id}").and_return(cached_data)
      allow(SlackBot::DevConsole).to receive(:log_check)
    end

    it "reloads data from storage" do
      callback.reload
      expect(callback.data).to eq(cached_data)
      expect(callback.args.to_s).to eq("foo=bar")
    end

    it "returns self" do
      expect(callback.reload).to eq(callback)
    end

    context "when callback is not found" do
      let(:cached_data) { nil }

      it "raises CallbackNotFound" do
        expect { callback.reload }.to raise_error(SlackBot::Errors::CallbackNotFound)
      end
    end
  end

  describe "#save" do
    before do
      allow(callback_storage_instance).to receive(:write).and_return(nil)
    end

    it "generates id if not present" do
      callback.save
      expect(callback.id).to be_present
    end

    it "writes data to storage" do
      callback.id = callback_id
      expect(callback_storage_instance).to receive(:write).with(
        "#{SlackBot::Callback::CALLBACK_KEY_PREFIX}:u#{user.id}:#{callback_id}",
        anything,
        expires_in: SlackBot::Callback::CALLBACK_RECORD_EXPIRES_IN
      )
      callback.save
    end
  end

  describe "#update" do
    before do
      callback.id = callback_id
      callback.data[:payload] = {existing: "data"}
      allow(callback_storage_instance).to receive(:write).and_return(nil)
    end

    it "merges payload with existing data" do
      callback.update({new: "data"})
      expect(callback.payload).to eq({existing: "data", new: "data"})
    end

    it "replaces payload if existing is not a hash" do
      callback.data[:payload] = "not a hash"
      callback.update({new: "data"})
      expect(callback.payload).to eq({new: "data"})
    end

    context "when id is blank" do
      before do
        callback.id = nil
      end

      it "does nothing" do
        expect(callback_storage_instance).not_to receive(:write)
        callback.update({new: "data"})
      end
    end

    context "when data is blank" do
      before do
        callback.instance_variable_set(:@data, nil)
      end

      it "does nothing" do
        expect(callback_storage_instance).not_to receive(:write)
        callback.update({new: "data"})
      end
    end
  end

  describe "#destroy" do
    before do
      callback.id = callback_id
      allow(callback_storage_instance).to receive(:delete).and_return(nil)
    end

    it "deletes data from storage" do
      expect(callback_storage_instance).to receive(:delete).with(
        "#{SlackBot::Callback::CALLBACK_KEY_PREFIX}:u#{user.id}:#{callback_id}"
      )
      callback.destroy
    end

    context "when view_id is present" do
      before do
        callback.view_id = "view_123"
      end

      it "deletes view storage key" do
        expect(callback_storage_instance).to receive(:delete).with(
          "#{SlackBot::Callback::CALLBACK_KEY_PREFIX}:u#{user.id}:view_123"
        )
        callback.destroy
      end
    end

    context "when id is blank" do
      before do
        callback.id = nil
      end

      it "does nothing" do
        expect(callback_storage_instance).not_to receive(:delete)
        callback.destroy
      end
    end
  end

  describe "#user" do
    it "finds user using callback_user_finder_method" do
      callback.data[:user_id] = user.id
      expect(callback.user).to eq(user)
    end

    context "when user_id is not present" do
      before do
        callback.data[:user_id] = nil
      end

      it "returns nil" do
        expect(callback.user).to be_nil
      end
    end
  end

  describe "#handler_class" do
    let(:handler_class) { Class.new }
    before do
      callback.data[:class_name] = "TestClass"
      allow(config).to receive(:find_handler_class).with("TestClass").and_return(handler_class)
    end

    it "finds handler class from config" do
      expect(callback.handler_class).to eq(handler_class)
    end

    context "when class_name is blank" do
      before do
        callback.data[:class_name] = nil
      end

      it "returns nil" do
        expect(callback.handler_class).to be_nil
      end
    end
  end

  describe "#handler_class=" do
    let(:handler_class) do
      Class.new do
        def self.name
          "NewHandlerClass"
        end
      end
    end

    before do
      callback.data[:class_name] = "OldClass"
      allow(config).to receive(:find_handler_class).with("OldClass").and_return(Class.new)
    end

    it "updates class_name to handler class name" do
      callback.handler_class = handler_class
      expect(callback.class_name).to eq("NewHandlerClass")
    end
  end

  describe "#read_view_callback_id" do
    before do
      callback.view_id = "view_123"
      allow(callback_storage_instance).to receive(:read).with(
        "#{SlackBot::Callback::CALLBACK_KEY_PREFIX}:u#{user.id}:view_123"
      ).and_return("callback_id_123")
    end

    it "reads callback_id from storage using view_id" do
      expect(callback.read_view_callback_id).to eq("callback_id_123")
    end

    context "when view_id is blank" do
      before do
        callback.view_id = nil
      end

      it "returns nil" do
        expect(callback.read_view_callback_id).to be_nil
      end
    end
  end

  describe "method_missing" do
    before do
      callback.data[:channel_id] = "C123"
      callback.data[:payload] = {"action_id" => "test_action"}
    end

    it "returns data value when key exists" do
      expect(callback.channel_id).to eq("C123")
    end

    it "returns payload value when key exists in payload" do
      expect(callback.action_id).to eq("test_action")
    end

    it "raises NoMethodError when key doesn't exist" do
      expect { callback.nonexistent }.to raise_error(NoMethodError)
    end
  end
end
