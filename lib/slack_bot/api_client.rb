require "faraday"

module SlackBot
  class ApiResponse
    # Cap in-request sleep so rate-limit retries do not hold web workers for Slack's default Retry-After.
    RATE_LIMIT_RETRY_SLEEP_SECONDS = 3

    attr_reader :response

    def self.from_request(&block)
      response = new(&block)
      return response unless response.rate_limited?

      Kernel.sleep(rate_limit_retry_sleep_seconds(response.retry_after))
      new(&block)
    end

    def self.rate_limit_retry_sleep_seconds(retry_after)
      [retry_after.to_i, RATE_LIMIT_RETRY_SLEEP_SECONDS].min
    end

    def initialize(&block)
      @response = block.call
      SlackBot::DevConsole.log_output "#{self.class.name}: #{response.body}"
    end

    def ok?
      response.status == 200 && data["ok"]
    end

    def error
      data["error"]
    end

    def rate_limited?
      response.status == 429 || (data["ok"] == false && data["error"] == "rate_limited")
    end

    def retry_after
      response.headers["Retry-After"]&.to_i || 60
    end

    def slack_error?
      !ok? && error.present?
    end

    def authentication_error?
      slack_error? && %w[invalid_auth account_inactive].include?(error)
    end

    def data
      JSON.parse(response.body)
    rescue JSON::ParserError => e
      SlackBot::Logger.error("Failed to parse Slack API response: #{e.message}")
      {"ok" => false, "error" => "invalid_json_response"}
    end
  end

  class ApiClient
    # Slack API base URL
    SLACK_API_BASE_URL = "https://slack.com/api/"
    # Request timeout in seconds
    REQUEST_TIMEOUT = 30
    # Connection timeout in seconds
    CONNECTION_TIMEOUT = 10
    TOKEN_FORMAT = /\Axox[bpa]-/

    attr_reader :client

    def initialize(authorization_token: ENV["SLACK_BOT_API_TOKEN"])
      validate_authorization_token!(authorization_token)
      @client = build_client(authorization_token)
    end

    def views_open(trigger_id:, view:)
      perform_request { client.post("views.open", {trigger_id: trigger_id, view: view}.to_json) }
    end

    def views_update(view_id:, view:)
      perform_request { client.post("views.update", {view_id: view_id, view: view}.to_json) }
    end

    def chat_post_message(channel:, text:, blocks:)
      perform_request { client.post("chat.postMessage", {channel: channel, text: text, blocks: blocks}.to_json) }
    end

    def chat_update(channel:, ts:, text:, blocks:)
      perform_request { client.post("chat.update", {channel: channel, ts: ts, text: text, blocks: blocks}.to_json) }
    end

    def chat_delete(channel:, ts:)
      perform_request { client.post("chat.delete", {channel: channel, ts: ts}.to_json) }
    end

    def chat_unfurl(channel:, ts:, unfurls:, source: nil, unfurl_id: nil, user_auth_blocks: nil, user_auth_message: nil, user_auth_required: nil, user_auth_url: nil)
      perform_request do
        client.post("chat.unfurl", {
          channel: channel,
          ts: ts,
          unfurls: unfurls,
          source: source,
          unfurl_id: unfurl_id,
          user_auth_blocks: user_auth_blocks,
          user_auth_message: user_auth_message,
          user_auth_required: user_auth_required,
          user_auth_url: user_auth_url
        }.to_json)
      end
    end

    def chat_schedule_message(channel:, text:, post_at:, blocks: nil)
      perform_request { client.post("chat.scheduleMessage", {channel: channel, text: text, post_at: post_at, blocks: blocks}.to_json) }
    end

    def scheduled_messages_list(channel: nil, cursor: nil, latest: nil, limit: nil, oldest: nil, team_id: nil)
      args = compact_payload(channel: channel, cursor: cursor, limit: limit, latest: latest, oldest: oldest, team_id: team_id)
      perform_request { client.post("scheduled_messages.list", args.to_json) }
    end

    def chat_delete_scheduled_message(channel:, scheduled_message_id:)
      perform_request { client.post("chat.deleteScheduledMessage", {channel: channel, scheduled_message_id: scheduled_message_id}.to_json) }
    end

    def chat_get_permalink(channel:, message_ts:)
      perform_request { client.post("chat.getPermalink", {channel: channel, message_ts: message_ts}.to_json) }
    end

    def users_info(user_id:)
      perform_request { client.post("users.info", {user: user_id}.to_json) }
    end

    def views_publish(user_id:, view:)
      perform_request { client.post("views.publish", {user_id: user_id, view: view}.to_json) }
    end

    def users_list(cursor: nil, limit: 200, include_locale: nil, team_id: nil)
      args = compact_payload(cursor: cursor, limit: limit, include_locale: include_locale, team_id: team_id)
      perform_request { client.post("users.list", args.to_json) }
    end

    def chat_post_ephemeral(channel:, user:, text:, as_user: nil, attachments: nil, blocks: nil, icon_emoji: nil, icon_url: nil, link_names: nil, parse: nil, thread_ts: nil, username: nil)
      args = compact_payload(
        channel: channel,
        user: user,
        text: text,
        as_user: as_user,
        attachments: attachments,
        blocks: blocks,
        icon_emoji: icon_emoji,
        icon_url: icon_url,
        link_names: link_names,
        parse: parse,
        thread_ts: thread_ts,
        username: username
      )
      perform_request { client.post("chat.postEphemeral", args.to_json) }
    end

    private

    def perform_request(&block)
      ApiResponse.from_request do
        block.call
      rescue Faraday::Error => e
        raise SlackBot::Errors::SlackApiError.new("Network error: #{e.message}")
      end
    end

    def validate_authorization_token!(authorization_token)
      raise SlackBot::Errors::SlackApiError.new("Slack bot API token is not set") unless valid_authorization_token?(authorization_token)
      return if authorization_token.start_with?("test_") || authorization_token.match?(TOKEN_FORMAT)

      raise SlackBot::Errors::SlackApiError.new("Invalid Slack API token format")
    end

    def valid_authorization_token?(authorization_token)
      authorization_token.is_a?(String) && !authorization_token.empty?
    end

    def build_client(authorization_token)
      Faraday.new do |conn|
        conn.request :url_encoded
        conn.adapter Faraday.default_adapter
        conn.url_prefix = SLACK_API_BASE_URL
        conn.headers["Content-Type"] = "application/json; charset=utf-8"
        conn.headers["Authorization"] = "Bearer #{authorization_token}"
        conn.options.timeout = REQUEST_TIMEOUT
        conn.options.open_timeout = CONNECTION_TIMEOUT
      end
    end

    def compact_payload(**payload)
      payload.compact
    end
  end
end
