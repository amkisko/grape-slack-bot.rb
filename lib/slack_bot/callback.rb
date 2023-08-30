require 'active_support/core_ext/object'
require 'active_support/core_ext/numeric/time'

module SlackBot
  class Callback
    CALLBACK_CACHE_KEY = "slack-bot-callback".freeze
    CALLBACK_RECORD_EXPIRES_IN = 15.minutes.freeze

    def self.find(id, config: nil)
      return if id.blank?

      callback = new(id: id, config: config)
      callback.reload
    rescue SlackBot::Errors::CallbackNotFound
      nil
    end

    def self.create(class_name:, user:, channel_id: nil, config: nil, extra: nil, expires_in: nil)
      callback =
        new(class_name: class_name, user: user, channel_id: channel_id, extra: extra, config: config)
      callback.save(expires_in: expires_in)
      callback
    end

    attr_reader :id, :data, :args, :config
    def initialize(id: nil, class_name: nil, user: nil, channel_id: nil, extra: nil, config: nil)
      @id = id
      @data = {
        class_name: class_name,
        user_id: user&.id,
        channel_id: channel_id,
        extra: extra
      }
      @args = SlackBot::Args.new
      @config = config || SlackBot::Config.current_instance
    end

    def reload
      cached_data = read_data
      SlackBot::DevConsole.log_check("SlackBot::Callback#read_data: #{id} | #{cached_data}")
      raise SlackBot::Errors::CallbackNotFound if cached_data.nil?

      @data = cached_data
      parse_args
      self
    end

    def save(expires_in: nil)
      @id = generate_id if id.blank?
      serialize_args
      update_timestamps

      SlackBot::DevConsole.log_check("SlackBot::Callback#write_data: #{id} | #{data}")
      write_data(data, expires_in: expires_in)
    end

    def update(payload, expires_in: nil)
      return if id.blank?
      return if data.blank?

      @data = data.merge(payload)
      save(expires_in: expires_in)
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

    def handler_class
      return if class_name.blank?

      config.find_handler_class(class_name)
    end

    def method_missing(method_name, *args, &block)
      return data[method_name.to_sym] if data.key?(method_name.to_sym)

      super
    end

    private

    def parse_args
      args.raw_args = data.fetch(:args)
    end

    def serialize_args
      data[:args] = args.to_s
    end

    def update_timestamps
      data[:created_at] ||= Time.current
      data[:updated_at] = Time.current
    end

    def generate_id
      SecureRandom.uuid
    end

    def read_data
      config.callback_storage_instance.read("#{CALLBACK_CACHE_KEY}:#{id}")
    end

    def write_data(data, expires_in: nil)
      expires_in ||= CALLBACK_RECORD_EXPIRES_IN
      config.callback_storage_instance.write("#{CALLBACK_CACHE_KEY}:#{id}", data, expires_in: expires_in)
    end

    def delete_data
      config.callback_storage_instance.delete("#{CALLBACK_CACHE_KEY}:#{id}")
    end
  end
end
