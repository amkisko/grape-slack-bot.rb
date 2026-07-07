module SlackBot
  module GrapeHelpers
    module Dispatch
      def events_callback(params)
        verify_slack_team!

        event = params[:event]
        return false if event.blank?
        return false if bot_message_event?(event)

        SlackBot::DevConsole.log_input "SlackApi::Events#events_callback: #{params.inspect}"
        handler = event_handler_for(params)
        return false if handler.blank?

        run_event_handler(handler, params)
      end

      def resolve_user_session(team_id, user_id)
        return if team_id.blank? || user_id.blank?

        config.user_session_resolver!.call(team_id, user_id)
      rescue SlackBot::Errors::ConfigurationError
        nil
      end

      def resolve_event_user(params)
        resolve_user_session(params[:team_id] || params["team_id"], fetch_user_id)&.user
      end

      def dispatch_event(handler:, params:, current_user:)
        config.event_dispatcher_method.call(handler: handler, params: params, current_user: current_user)
        false
      end

      private

      def bot_message_event?(event)
        (event[:subtype] || event["subtype"]) == "bot_message"
      end

      def event_handler_for(params)
        event_type = params[:event][:type] || params[:event]["type"]
        config.find_event_handler(event_type.to_sym)
      end

      def run_event_handler(handler, params)
        current_user = resolve_event_user(params)
        return dispatch_event(handler: handler, params: params, current_user: current_user) if config.event_dispatcher_method

        handler.new(params: params, current_user: current_user).call
      end
    end
  end
end
