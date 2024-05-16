require "active_support/core_ext/object"
require "active_support/core_ext/numeric/time"

module SlackBot
  class Callback
    CALLBACK_KEY_PREFIX = "slack-bot-callback".freeze
    CALLBACK_RECORD_EXPIRES_IN = 15.minutes.freeze

    def self.find(id, user: nil, config: nil)
      return if id.blank?

      callback = new(id: id, user: user, config: config)
      callback.reload
    rescue SlackBot::Errors::CallbackNotFound
      nil
    end

    def self.find_by_view_id(view_id, user: nil, config: nil)
      callback = new(view_id: view_id, user: user, config: config)
      callback_id = callback.read_view_callback_id
      return if callback_id.blank?

      find(callback_id, user: user, config: config)
    end

    def self.create(class_name:, user:, id: nil, channel_id: nil, config: nil, payload: nil, expires_in: nil, user_scope: nil)
      callback =
        new(id: id, class_name: class_name, user: user, channel_id: channel_id, payload: payload, config: config, expires_in: expires_in, user_scope: user_scope)
      callback.save
      callback
    end

    def self.find_or_create(id:, class_name:, user:, channel_id: nil, config: nil, payload: nil, expires_in: nil, user_scope: nil)
      callback = find(id, user: user, config: config)
      return callback if callback.present?

      create(id: id, class_name: class_name, user: user, channel_id: channel_id, payload: payload, config: config, expires_in: expires_in, user_scope: user_scope)
    end

    attr_reader :id, :data, :args, :config, :expires_in, :user_scope
    def initialize(id: nil, class_name: nil, user: nil, channel_id: nil, payload: nil, config: nil, expires_in: nil, user_scope: nil, view_id: nil)
      @id = id
      @data = {
        class_name: class_name,
        user_id: user&.id,
        channel_id: channel_id,
        view_id: view_id,
        payload: payload
      }
      @args = SlackBot::Args.new
      @config = config || SlackBot::Config.current_instance
      @expires_in = expires_in || CALLBACK_RECORD_EXPIRES_IN
      @user_scope = user_scope.nil? ? true : user_scope
    end

    def reload
      cached_data = read_data
      SlackBot::DevConsole.log_check("SlackBot::Callback#read_data: #{id} | #{cached_data}")
      raise SlackBot::Errors::CallbackNotFound if cached_data.nil?

      @data = cached_data
      parse_args
      self
    end

    def save
      @id = generate_id if id.blank?
      serialize_args

      SlackBot::DevConsole.log_check("SlackBot::Callback#write_data: #{id} | #{data}")
      write_data(data)
    end

    def update(payload)
      return if id.blank?
      return if data.blank?

      @data[:payload] = if @data[:payload].is_a?(Hash)
        @data[:payload].merge(payload)
      else
        payload
      end

      save
    end

    def destroy
      return if id.blank?

      delete_data
    end

    def user
      @user ||= begin
        user_id = data&.dig(:user_id)
        config.callback_user_finder_method.call(user_id) if user_id.present?
      end
    end

    def user=(user)
      @user = user
      @data[:user_id] = user&.id
    end

    def class_name=(class_name)
      @data[:class_name] = class_name
    end

    def channel_id=(channel_id)
      @data[:channel_id] = channel_id
    end

    def payload=(payload)
      @data[:payload] = payload
    end

    def view_id=(view_id)
      @data[:view_id] = view_id
    end

    def handler_class=(handler_class)
      new_class_name = handler_class&.name
      config.find_handler_class(class_name)

      self.class_name = new_class_name
    end

    def handler_class
      return if class_name.blank?

      config.find_handler_class(class_name)
    end

    def method_missing(method_name, *args, &block)
      return data[method_name.to_sym] if data.key?(method_name.to_sym)
      return data[:payload][method_name.to_s] if data[:payload].is_a?(Hash) && data[:payload].key?(method_name.to_s)

      super
    end

    def read_view_callback_id
      return if view_id.blank?

      config.callback_storage_instance.read(view_storage_key)
    end

    private

    def parse_args
      args.raw_args = data.fetch(:args)
    end

    def serialize_args
      @data[:args] = args.to_s
    end

    def generate_id
      SecureRandom.hex(10)
    end

    def storage_key
      raise "User is required for scoped callback" if user.blank?

      "#{CALLBACK_KEY_PREFIX}:u#{user.id}:#{id}"
    end

    def view_storage_key
      raise "User is required for scoped callback" if user.blank?

      "#{CALLBACK_KEY_PREFIX}:u#{user.id}:#{view_id}"
    end

    def read_data
      config.callback_storage_instance.read(storage_key)
    end

    def write_data(data, expires_in: nil)
      expires_in ||= CALLBACK_RECORD_EXPIRES_IN
      config.callback_storage_instance.write(view_storage_key, id, expires_in: expires_in) if view_id.present?
      config.callback_storage_instance.write(storage_key, data, expires_in: expires_in)
    end

    def delete_data
      config.callback_storage_instance.delete(view_storage_key) if view_id.present?
      config.callback_storage_instance.delete(storage_key)
    end
  end
end
