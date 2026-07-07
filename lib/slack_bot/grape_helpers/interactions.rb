module SlackBot
  module GrapeHelpers
    module Interactions
      def route_interaction(payload:, user:, params:)
        case payload["type"]
        when "view_submission"
          handle_block_actions_view(view: payload["view"], user: user, params: params)
        when "block_actions"
          if payload["view"].present?
            handle_block_actions_view(view: payload["view"], user: user, params: params)
          else
            handle_block_actions_message(payload: payload, user: user, params: params)
          end
        else
          raise SlackBot::Errors::UnknownActionTypeError.new(payload["type"])
        end
      end

      def handle_block_actions_message(payload:, user:, params:)
        action_id = payload.dig("actions", 0, "action_id")
        return false if action_id.blank?

        interaction_klass = config.find_block_action(action_id)
        raise SlackBot::Errors::BlockActionNotImplemented.new if interaction_klass.blank?

        interaction_klass.new(current_user: user, params: params, config: config).call
      end

      def validate_callback_user!(callback, user)
        if callback.user_id != user.id
          raise SlackBot::Errors::CallbackUserMismatchError.new("Callback user is not equal to action user")
        end
      end

      def handle_block_actions_view(view:, user:, params:)
        callback = find_callback!(view: view, user: user)
        log_callback_check(callback, user)
        validate_callback_user!(callback, user)

        interaction_klass = callback_interaction_klass(callback)
        return false if interaction_klass.blank?

        interaction_klass.new(current_user: user, params: params, callback: callback, config: config).call
      end

      private

      def find_callback!(view:, user:)
        callback = SlackBot::Callback.find(view&.dig("callback_id"), user: user, config: config)
        raise SlackBot::Errors::CallbackNotFound.new if callback.blank?

        callback
      end

      def log_callback_check(callback, user)
        SlackBot::DevConsole.log_check "SlackApi::Interactions##{__method__}: #{callback.id} #{callback.payload} #{callback.user_id} #{user&.id}"
      end

      def callback_interaction_klass(callback)
        handler_class_obj = callback.handler_class
        handler_class_obj&.interaction_klass if handler_class_obj&.respond_to?(:interaction_klass)
      end
    end
  end
end
