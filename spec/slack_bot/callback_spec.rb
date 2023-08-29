require 'spec_helper'

module SlackBot
  class Callback
    CALLBACK_CACHE_KEY = "slack-bot-callback".freeze

    def self.find(id, config: nil)
      callback = new(id: id, config: config)
      callback.reload
    end

    def self.create(class_name:, method_name:, user:, channel_id: nil, config: nil)
      callback =
        new(class_name: class_name, method_name: method_name, user: user, channel_id: channel_id, config: config)
      callback.save
      callback
    end

    attr_reader :id, :data, :args, :config, :extra
    def initialize(id: nil, class_name: nil, method_name: nil, user: nil, channel_id: nil, extra: nil, config: nil)
      @id = id
      @data = {
        class_name: class_name,
        method_name: method_name,
        user_id: user&.id,
        channel_id: channel_id,
        extra: extra
      }
      @args = SlackBot::Args.new
      @config = config || SlackBot::Config.current_instance
    end

    def reload
      @data = read_data
      SlackBot::DevConsole.log_check("SlackBot::Callback#read_data: #{id} | #{data}")

      parse_args
      self
    end

    def save
      generate_id if id.blank?
      serialize_args

      SlackBot::DevConsole.log_check("SlackBot::Callback#write_data: #{id} | #{data}")
      write_data(data)
    end

    def update(payload)
      return if id.blank?
      return if data.blank?

      @data = data.merge(payload)
      save
    end

    def destroy
      return if id.blank?

      delete_data
    end

    def klass
      data&.dig(:class_name)&.constantize
    end

    def user
      @user ||= begin
        user_id = data&.dig(:user_id)
        config.callback_user_finder_method.call(user_id) if user_id.present?
      end
    end

    def user_id
      data&.dig(:user_id)
    end

    def channel_id
      data&.dig(:channel_id)
    end

    def method_name
      data&.dig(:method_name)
    end

    private

    def parse_args
      args.raw_args = data&.dig(:args)
    end

    def serialize_args
      data[:args] = args.to_s
    end

    def generate_id
      @id = SecureRandom.uuid
    end

    def read_data
      config.callback_storage_instance.read("#{CALLBACK_CACHE_KEY}:#{id}")
    end

    def write_data(data)
      config.callback_storage_instance.write("#{CALLBACK_CACHE_KEY}:#{id}", data, expires_in: 1.hour)
    end

    def delete_data
      config.callback_storage_instance.delete("#{CALLBACK_CACHE_KEY}:#{id}")
    end
  end
end


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
  let(:callback_storage_instance) { instance_double(SlackBot::CallbackStorage, read: nil, write: nil, delete: nil) }
  let(:callback_user_finder_method) { ->(user_id) { user } }

  let(:user) { double(:user, id: 1) }

  let(:callback_id) { "test_callback_id" }

  describe ".find" do
    subject(:find) { described_class.find(callback_id) }

    before do
      # allow(callback_storage_instance).to receive(:read).with("slack-bot-callback:test_callback_id").and_return(data)
    end

    context "when callback is found" do
      let(:data) { { class_name: "Test", method_name: "test", user_id: 1, channel_id: "test_channel_id", extra: { test: "test" } } }

      it "returns callback" do
        expect(find).to be_a(described_class)
        expect(find.id).to eq(callback_id)
        expect(find.klass).to eq(Test)
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
        expect(find).to be_nil
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
