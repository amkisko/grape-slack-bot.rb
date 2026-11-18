require "active_support/core_ext/class/attribute"

module SlackBot
  class Schema
    class_attribute :registrations, instance_accessor: false, default: {}.freeze

    %i[callback_storage callback_user_finder user_session_resolver event_dispatcher].each do |setting|
      define_singleton_method(setting) do |value|
        self.registrations = registrations.merge([setting] => [value].freeze).freeze
      end
    end

    %i[slash_command event block_actions shortcut message_action view_closed block_suggestion].each do |route|
      define_singleton_method(route) do |key, handler|
        identifier = key.to_s.dup.freeze
        self.registrations = registrations.merge([route, identifier].freeze => [identifier, handler].freeze).freeze
      end
    end

    def self.options(action_id, handler)
      block_suggestion(action_id, handler)
    end

    def self.mount(schema)
      self.registrations = registrations.merge(schema.registrations).freeze
      self
    end
  end
end

require "slack_bot/schema/registrar"
require "slack_bot/schema/slash_command_group"
require "slack_bot/schema/input_object"
require "slack_bot/schema/responses"
require "slack_bot/schema/view_owner"
require "slack_bot/schema/slack_responses"
require "slack_bot/schema/handlers"
require "slack_bot/schema/block_actions"
require "slack_bot/schema/view_submission"
