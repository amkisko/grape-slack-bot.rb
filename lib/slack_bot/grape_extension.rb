# frozen_string_literal: true

require "active_support"
require "active_support/core_ext/object"
require "active_support/security_utils"

require_relative "grape_helpers/dispatch"
require_relative "grape_helpers/interactions"

module SlackBot
  module GrapeHelpers
    include Dispatch
    include Interactions

    # Slack recommends rejecting requests older than 5 minutes
    TIMESTAMP_TOLERANCE_SECONDS = 300
    # Minimum length for Slack signing secret (Slack's requirement)
    MIN_SIGNING_SECRET_LENGTH = 32
    PAYLOAD_OBJECTS = %w[team user view].freeze
    ROUTE_IDENTIFIERS = %w[callback_id action_id].freeze
    NEW_INTERACTION_TYPES = %w[shortcut message_actions message_action view_closed].freeze

    def fetch_team_id
      params.dig("team_id") || params.dig("team", "id")
    end

    def fetch_user_id
      params.dig("user_id") || params.dig("user", "id") || params.dig("event", "user")
    end

    def current_user
      resolve_user_session(fetch_team_id, fetch_user_id)&.user
    end

    def verify_slack_signature!
      remove_instance_variable(:@request_body_content) if instance_variable_defined?(:@request_body_content)

      slack_signing_secret = ENV["SLACK_SIGNING_SECRET"]
      timestamp = slack_request_header("x-slack-request-timestamp", "X-Slack-Request-Timestamp")
      slack_signature = slack_request_header("x-slack-signature", "X-Slack-Signature")

      validate_signature_headers!(slack_signing_secret, timestamp, slack_signature)
      validate_request_timestamp!(timestamp)
      verify_signature_match!(slack_signing_secret, timestamp, slack_signature)
    end

    def verify_slack_team!(team_id = nil)
      slack_team_id = ENV["SLACK_TEAM_ID"]
      requested_team_id = team_id || fetch_team_id
      if slack_team_id.present? && slack_team_id == requested_team_id
        true
      else
        raise SlackBot::Errors::TeamAuthenticationError.new("Team is not authorized")
      end
    end

    def interaction_team_id(payload)
      payload.dig("team", "id") || payload["team_id"] || payload.dig("user", "team_id")
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

    def slack_bot_config
      @slack_bot_config ||= SlackBot::Config.current_instance
    end

    def slack_request_retry?
      slack_request_header("x-slack-retry-num", "X-Slack-Retry-Num").present?
    end

    def url_verification(params)
      SlackBot::DevConsole.log_input "Slack URL verification"
      {challenge: params[:challenge]}
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
      request_timestamp = Integer(timestamp, 10)
      current_timestamp = Time.now.to_i
      return if (current_timestamp - request_timestamp).abs <= TIMESTAMP_TOLERANCE_SECONDS

      raise SlackBot::Errors::SignatureAuthenticationError.new("Request timestamp too old")
    end

    def verify_signature_match!(slack_signing_secret, timestamp, slack_signature)
      body = request_body_content
      sig_basestring = "v0:#{timestamp}:#{body}"
      expected_digest_bin = OpenSSL::HMAC.digest("SHA256", slack_signing_secret, sig_basestring)
      actual_hex = slack_signature.delete_prefix("v0=")
      return true if ActiveSupport::SecurityUtils.secure_compare(expected_digest_bin, [actual_hex].pack("H*"))

      raise SlackBot::Errors::SignatureAuthenticationError.new("Signature mismatch")
    end

    def request_body_content
      return @request_body_content if instance_variable_defined?(:@request_body_content)

      return @request_body_content = "" unless request.body

      request.body.rewind if request.body.respond_to?(:rewind)
      body_content = request.body.read
      request.body.rewind if request.body.respond_to?(:rewind)

      @request_body_content = body_content
    end

    def parse_interaction_payload!(raw_payload)
      payload = JSON.parse(raw_payload) if raw_payload.is_a?(String)
      raise SlackBot::Errors::InvalidPayloadError.new("Invalid JSON payload: expected an object") unless payload.is_a?(Hash)

      validate_interaction_shape!(payload)
      payload
    rescue JSON::ParserError
      raise SlackBot::Errors::InvalidPayloadError.new("Invalid JSON payload"), cause: nil
    end

    def validate_interaction_shape!(payload)
      return if PAYLOAD_OBJECTS.all? { |field| payload[field].nil? || payload[field].is_a?(Hash) } &&
        ROUTE_IDENTIFIERS.all? { |field| payload[field].nil? || payload[field].is_a?(String) } &&
        valid_action_list?(payload["actions"])

      raise SlackBot::Errors::InvalidPayloadError.new("Invalid Slack payload fields")
    end

    def valid_action_list?(actions)
      actions.nil? || (actions.is_a?(Array) && actions.all? do |action|
        action.is_a?(Hash) && (action["action_id"].nil? || action["action_id"].is_a?(String))
      end)
    end

    def authorize_interaction_team!(payload)
      team_id = interaction_team_id(payload)
      raise SlackBot::Errors::TeamAuthenticationError.new("Team is not authorized") if team_id.blank?

      verify_slack_team!(team_id)
      team_id
    end

    def resolve_action_user(payload, team_id)
      resolve_user_session(team_id, payload.dig("user", "id"))
    end

    def load_menu_options(options_params, user)
      klass = slack_bot_config.find_menu_options(options_params[:action_id])
      raise SlackBot::Errors::MenuOptionsNotImplemented.new if klass.blank?

      klass.new(current_user: user, params: options_params, config: slack_bot_config).call
    end

    def empty_slack_ack!
      api_format :txt
      blank_slack_response!
    end

    def invoke_slack_handler(handler)
      result = handler.call
      if handler.is_a?(Schema::Responses)
        return empty_slack_ack! if result.blank?

        status 200
      end

      result
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
      base.rescue_from SlackBot::Errors::SignatureAuthenticationError do |e|
        error!({error: e.message}, 401)
      end
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
          command_config = slack_bot_config.find_slash_command_config(params[:url_token], params[:command], params[:text])
          command_klass = command_config&.command_klass
          raise SlackBot::Errors::SlashCommandNotImplemented.new if command_klass.blank?

          args = params[:text].to_s.sub(/\A#{Regexp.escape(command_config.full_token)}\s?/, "")
          SlackBot::DevConsole.log_input "Slack slash command"

          action = command_klass.new(current_user: current_user, params: params, args: args, config: slack_bot_config)
          verify_slack_team! if action.only_slack_team?
          verify_direct_message_channel! if action.only_direct_message?
          verify_current_user! if action.only_user?

          result = invoke_slack_handler(action)
          return blank_slack_response! unless result

          result
        end
      end
    end

    def self.add_interactions_resource!(base)
      base.resource :interactions do
        post do
          payload = parse_interaction_payload!(request.POST["payload"])
          team_id = authorize_interaction_team!(payload)
          action_user = resolve_action_user(payload, team_id)&.user

          result = route_interaction(payload: payload, user: action_user, params: params)

          status 200 if GrapeHelpers::NEW_INTERACTION_TYPES.include?(payload["type"])
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
          SlackBot::DevConsole.log_input "Slack menu options"

          verify_slack_team!
          menu_options = load_menu_options(params, current_user)
          return blank_slack_response! if menu_options.blank?

          menu_options
        end

        post do
          payload = parse_interaction_payload!(request.POST["payload"])
          team_id = authorize_interaction_team!(payload)
          raise SlackBot::Errors::UnknownActionTypeError.new(payload["type"]) unless payload["type"] == "block_suggestion"

          user = resolve_action_user(payload, team_id)&.user
          status 200
          load_menu_options(payload.with_indifferent_access, user).presence || {options: []}
        end
      end
    end
  end
end
