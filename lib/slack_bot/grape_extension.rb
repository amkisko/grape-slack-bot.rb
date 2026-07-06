require "active_support"
require "active_support/core_ext/object"
require "active_support/security_utils"

module SlackBot
  module GrapeHelpers
    # Slack recommends rejecting requests older than 5 minutes
    TIMESTAMP_TOLERANCE_SECONDS = 300
    # Minimum length for Slack signing secret (Slack's requirement)
    MIN_SIGNING_SECRET_LENGTH = 32

    def fetch_team_id
      params.dig("team_id") || params.dig("team", "id")
    end

    def fetch_user_id
      params.dig("user_id") || params.dig("user", "id") || params.dig("event", "user")
    end

    def verify_slack_signature!
      slack_signing_secret = ENV["SLACK_SIGNING_SECRET"]
      timestamp = slack_request_header("x-slack-request-timestamp", "X-Slack-Request-Timestamp")
      slack_signature = slack_request_header("x-slack-signature", "X-Slack-Signature")

      validate_signature_headers!(slack_signing_secret, timestamp, slack_signature)
      validate_request_timestamp!(timestamp)
      verify_signature_match!(slack_signing_secret, timestamp, slack_signature)
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
      return true if current_user

      raise SlackBot::Errors::UserAuthenticationError.new("User is not authorized")
    end

    def slack_request_retry?
      slack_request_header("x-slack-retry-num", "X-Slack-Retry-Num").present?
    end

    def events_callback(params)
      verify_slack_team!

      event = params[:event]
      return false if event.blank?

      subtype = event[:subtype] || event["subtype"]
      return false if subtype == "bot_message"

      SlackBot::DevConsole.log_input "SlackApi::Events#events_callback: #{params.inspect}"
      handler = config.find_event_handler(event[:type].to_sym)
      return false if handler.blank?

      event = handler.new(params: params, current_user: current_user)
      event.call
    end

    def url_verification(params)
      SlackBot::DevConsole.log_input "SlackApi::Events#url_verification: #{params.inspect}"
      {challenge: params[:challenge]}
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

    def slack_request_header(*names)
      names.each do |name|
        header = request.headers[name]
        return header if header
      end

      nil
    end

    def validate_signature_headers!(slack_signing_secret, timestamp, slack_signature)
      raise SlackBot::Errors::SignatureAuthenticationError.new("Missing signature headers") if slack_signing_secret.blank? || timestamp.blank? || slack_signature.blank?
      return if slack_signing_secret.start_with?("test_") || slack_signing_secret.length >= MIN_SIGNING_SECRET_LENGTH

      raise SlackBot::Errors::SignatureAuthenticationError.new("Invalid signing secret format")
    end

    def validate_request_timestamp!(timestamp)
      request_timestamp = timestamp.to_i
      current_timestamp = Time.now.to_i
      return if (current_timestamp - request_timestamp).abs <= TIMESTAMP_TOLERANCE_SECONDS

      raise SlackBot::Errors::SignatureAuthenticationError.new("Request timestamp too old")
    end

    def verify_signature_match!(slack_signing_secret, timestamp, slack_signature)
      return true if ActiveSupport::SecurityUtils.secure_compare(computed_signature(slack_signing_secret, timestamp), slack_signature)

      raise SlackBot::Errors::SignatureAuthenticationError.new("Signature mismatch")
    end

    def computed_signature(slack_signing_secret, timestamp)
      sig_basestring = "v0:#{timestamp}:#{request_body_content}"
      "v0=" + OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new("sha256"), slack_signing_secret, sig_basestring)
    end

    def request_body_content
      return "" unless request.body

      request.body.rewind if request.body.respond_to?(:rewind)
      body_content = request.body.read
      request.body.rewind if request.body.respond_to?(:rewind)
      body_content
    end

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

    def parse_interaction_payload!(raw_payload)
      JSON.parse(raw_payload)
    rescue JSON::ParserError => e
      raise SlackBot::Errors::InvalidPayloadError.new("Invalid JSON payload: #{e.message}")
    end

    def resolve_action_user(payload)
      resolve_user_session(payload.dig("user", "team_id"), payload.dig("user", "id"))
    end

    def blank_slack_response!
      body false
      status 200
    end
  end

  module GrapeExtension
    def self.included(base)
      configure_base!(base)
      add_commands_resource!(base)
      add_interactions_resource!(base)
      add_events_resource!(base)
      add_menu_options_resource!(base)
    end

    def self.configure_base!(base)
      base.format :json
      base.content_type :json, "application/json"
      base.use ActionDispatch::RemoteIp if defined?(ActionDispatch::RemoteIp)
      base.helpers SlackBot::GrapeHelpers
      base.rescue_from SlackBot::Error do |e|
        error!({error: e.message}, 200)
      end
      base.before do
        verify_slack_signature!
      end
    end

    def self.add_commands_resource!(base)
      base.resource :commands do
        post ":url_token" do
          command_config = config.find_slash_command_config(params[:url_token], params[:command], params[:text])
          command_klass = command_config&.command_klass
          raise SlackBot::Errors::SlashCommandNotImplemented.new if command_klass.blank?

          args = params[:text].gsub(/^#{command_config.full_token}\s?/, "")
          SlackBot::DevConsole.log_input "SlackApi::SlashCommands#post: #{command_config.url_token} | #{command_config.full_token} | #{args}"

          action = command_klass.new(current_user: current_user, params: params, args: args, config: config)
          verify_slack_team! if action.only_slack_team?
          verify_direct_message_channel! if action.only_direct_message?
          verify_current_user! if action.only_user?

          result = action.call
          return blank_slack_response! unless result

          result
        end
      end
    end

    def self.add_interactions_resource!(base)
      base.resource :interactions do
        post do
          payload = parse_interaction_payload!(params[:payload])
          action_user = resolve_action_user(payload)&.user

          result = case payload["type"]
          when "block_actions", "view_submission"
            handle_block_actions_view(view: payload["view"], user: action_user, params: params)
          else
            raise SlackBot::Errors::UnknownActionTypeError.new(payload["type"])
          end

          return blank_slack_response! if result.blank? || result == false

          result
        end
      end
    end

    def self.add_events_resource!(base)
      base.resource :events do
        post do
          return blank_slack_response! if slack_request_retry?

          result = case params[:type]
          when "url_verification"
            url_verification(params)
          when "event_callback"
            events_callback(params)
          else
            raise SlackBot::Errors::UnknownActionTypeError.new(params[:type])
          end

          return blank_slack_response! if result.blank? || result == false

          result
        end
      end
    end

    def self.add_menu_options_resource!(base)
      base.resource :menu_options do
        get do
          SlackBot::DevConsole.log_input "SlackApi::MenuOptions#get: #{params.inspect}"

          menu_options_klass = config.find_menu_options(params[:action_id])
          raise SlackBot::Errors::MenuOptionsNotImplemented.new if menu_options_klass.blank?

          menu_options = menu_options_klass.new(current_user: current_user, params: params, config: config).call
          return blank_slack_response! if menu_options.blank?

          menu_options
        end
      end
    end
  end
end
