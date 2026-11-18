# frozen_string_literal: true

module SlackBot
  module GrapeHelpers
    module Interactions
      def route_interaction(payload:, user:, params:)
        type = payload["type"]
        case type
        when "view_submission", "view_closed"
          route_view(payload, user, params, type)
        when "block_actions"
          route_block_actions(payload, user, params)
        when "shortcut"
          run_registered_interaction(type, payload["callback_id"], user, params, payload)
        when "message_actions", "message_action"
          run_registered_interaction("message_action", payload["callback_id"], user, params, payload)
        else
          raise SlackBot::Errors::UnknownActionTypeError.new(type)
        end
      end

      def handle_block_actions_message(payload:, user:, params:)
        action_id = payload.dig("actions", 0, "action_id")
        return false if action_id.blank?

        interaction_klass = slack_bot_config.find_block_action(action_id)
        raise SlackBot::Errors::BlockActionNotImplemented.new if interaction_klass.blank?

        handler = interaction_klass.new(current_user: user, params: params, config: slack_bot_config)
        invoke_interaction(handler, payload)
      end

      def validate_callback_user!(callback, user)
        if user.nil? || callback.user_id != user.id
          raise SlackBot::Errors::CallbackUserMismatchError.new("Callback user is not equal to action user")
        end
      end

      def handle_block_actions_view(view:, user:, params:, type: "block_actions", payload: nil)
        callback_id = view&.dig("callback_id")
        callback = find_view_callback(view, user, type)
        if callback.nil?
          return run_registered_interaction(type, callback_id, user, params, payload) if type == "view_closed"

          raise SlackBot::Errors::CallbackNotFound
        end

        validate_callback_user!(callback, user)
        interaction_klass = callback_interaction_klass(callback, type)
        return false if interaction_klass.blank?

        handler = interaction_klass.new(current_user: user, params: params, callback: callback, config: slack_bot_config)
        invoke_interaction(handler, payload)
      end

      private

      def find_view_callback(view, user, type)
        return if user.nil?
        return if type == "view_closed" && slack_bot_config.callback_storage_instance.nil?

        callback_id = view&.dig("callback_id")
        if callback_id.present?
          SlackBot::Callback.find(callback_id, user: user, config: slack_bot_config)
        elsif view&.dig("id").present?
          SlackBot::Callback.find_by_view_id(view["id"], user: user, config: slack_bot_config)
        end
      end

      def route_block_actions(payload, user, params)
        view = payload["view"]
        if view.blank? || (view["type"] == "home" && view["callback_id"].blank?)
          handle_block_actions_message(payload: payload, user: user, params: params)
        else
          route_view(payload, user, params, "block_actions")
        end
      end

      def route_view(payload, user, params, type)
        handle_block_actions_view(view: payload["view"], user: user, params: params, type: type, payload: payload)
      end

      def run_registered_interaction(type, callback_id, user, params, payload)
        klass = slack_bot_config.find_interaction_callback(type, callback_id)
        return empty_slack_ack! unless klass

        handler = klass.new(current_user: user, params: params, config: slack_bot_config)
        invoke_interaction(handler, payload).presence || empty_slack_ack!
      end

      def invoke_interaction(handler, payload)
        handler.payload = payload if payload && handler.is_a?(SlackBot::Interaction)
        invoke_slack_handler(handler)
      end

      def callback_interaction_klass(callback, type)
        owner = callback.handler_class
        if owner.respond_to?(:interaction_handlers)
          owner.interaction_handlers[type]
        elsif type != "view_closed" && owner.respond_to?(:interaction_klass)
          owner.interaction_klass
        end
      end
    end
  end
end
