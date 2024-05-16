require "active_support"
require "active_support/core_ext/object"

module SlackBot
  module GrapeHelpers
    def fetch_team_id
      params.dig("team_id") || params.dig("team", "id")
    end

    def fetch_user_id
      params.dig("user_id") || params.dig("user", "id") || params.dig("event", "user")
    end

    def verify_slack_signature!
      slack_signing_secret = ENV.fetch("SLACK_SIGNING_SECRET")
      timestamp = request.headers["X-Slack-Request-Timestamp"]
      request_body = request.body.read
      sig_basestring = "v0:#{timestamp}:#{request_body}"
      my_signature =
        "v0=" +
        OpenSSL::HMAC.hexdigest(
          OpenSSL::Digest.new("sha256"),
          slack_signing_secret,
          sig_basestring
        )
      slack_signature = request.headers["X-Slack-Signature"]
      if ActiveSupport::SecurityUtils.secure_compare(
        my_signature,
        slack_signature
      )
        true
      else
        raise SlackBot::Errors::SignatureAuthenticationError.new("Signature mismatch")
      end
    end

    def verify_slack_team!
      slack_team_id = ENV.fetch("SLACK_TEAM_ID")
      if slack_team_id == fetch_team_id
        true
      else
        raise SlackBot::Errors::TeamAuthenticationError.new("Team is not authorized")
      end
    end

    def verify_direct_message_channel!
      if params[:channel_name] == "directmessage"
        true
      else
        raise SlackBot::Errors::ChannelAuthenticationError.new(
          "This command is only available in direct messages"
        )
      end
    end

    def verify_current_user!
      if current_user
        true
      else
        raise SlackBot::Errors::UserAuthenticationError.new("User is not authorized")
      end
    end

    def events_callback(params)
      verify_slack_team!

      SlackBot::DevConsole.log_input "SlackApi::Events#events_callback: #{params.inspect}"
      handler = config.find_event_handler(params[:event][:type].to_sym)
      return if handler.blank?

      event = handler.new(params: params, current_user: current_user)
      event.call
    end

    def url_verification(params)
      SlackBot::DevConsole.log_input "SlackApi::Events#url_verification: #{params.inspect}"
      {challenge: params[:challenge]}
    end

    def handle_block_actions_view(view:, user:, params:)
      callback_id = view&.dig("callback_id")

      callback = SlackBot::Callback.find(callback_id, user: user, config: config)
      raise SlackBot::Errors::CallbackNotFound.new if callback.blank?

      SlackBot::DevConsole.log_check "SlackApi::Interactions##{__method__}: #{callback.id} #{callback.payload} #{callback.user_id} #{user&.id}"

      if callback.user_id != user.id
        raise "Callback user is not equal to action user"
      end

      interaction_klass = callback.handler_class&.interaction_klass
      return if interaction_klass.blank?

      interaction_klass.new(current_user: user, params: params, callback: callback, config: config).call
    end
  end

  module GrapeExtension
    def self.included(base)
      base.format :json
      base.content_type :json, "application/json"
      base.use ActionDispatch::RemoteIp
      base.helpers SlackBot::GrapeHelpers

      base.before do
        verify_slack_signature!
      end

      base.resource :commands do
        post ":url_token" do
          command_config = config.find_slash_command_config(params[:url_token], params[:command], params[:text])
          command_klass = command_config&.command_klass
          raise SlackBot::Errors::SlashCommandNotImplemented.new if command_klass.blank?

          args = params[:text].gsub(/^#{command_config.full_token}\s?/, "")
          SlackBot::DevConsole.log_input "SlackApi::SlashCommands#post: #{command_config.url_token} | #{command_config.full_token} | #{args}"

          action =
            command_klass.new(
              current_user: current_user,
              params: params,
              args: args,
              config: config
            )
          verify_slack_team! if action.only_slack_team?
          verify_direct_message_channel! if action.only_direct_message?
          verify_current_user! if action.only_user?

          result = action.call
          return body false if !result

          result
        end
      end

      base.resource :interactions do
        post do
          payload = JSON.parse(params[:payload])

          action_user_session =
            resolve_user_session(
              payload.dig("user", "team_id"),
              payload.dig("user", "id")
            )
          action_user = action_user_session&.user

          action_type = payload["type"]
          result = case action_type
          when "block_actions", "view_submission"
            handle_block_actions_view(
              view: payload["view"],
              user: action_user,
              params: params
            )
          else
            raise "Unknown action type: #{action_type}"
          end

          return body false if result.blank?

          result
        end
      end

      base.resource :events do
        post do
          result =
            case params[:type]
            when "url_verification"
              url_verification(params)
            when "event_callback"
              events_callback(params)
            end

          return body false if result.blank?

          result
        end
      end

      base.resource :menu_options do
        get do
          SlackBot::DevConsole.log_input "SlackApi::MenuOptions#get: #{params.inspect}"

          action_id = params[:action_id]
          menu_options_klass = config.find_menu_options(action_id)
          raise SlackBot::Errors::MenuOptionsNotImplemented.new if menu_options_klass.blank?

          menu_options = menu_options_klass.new(current_user: current_user, params: params, config: config).call
          return body false if menu_options.blank?

          menu_options
        end
      end
    end
  end
end
