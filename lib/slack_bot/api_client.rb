require 'faraday'

module SlackBot
  class ApiResponse
    attr_reader :response
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

    def data
      JSON.parse(response.body)
    end
  end
  class ApiClient
    attr_reader :client
    def initialize(authorization_token: ENV["SLACK_BOT_API_TOKEN"])
      authorization_token_available = !authorization_token.nil? && authorization_token.is_a?(String) && !authorization_token.empty?
      raise "Slack bot API token is not set" if !authorization_token_available

      @client =
        Faraday.new do |conn|
          conn.request :url_encoded
          conn.adapter Faraday.default_adapter
          conn.url_prefix = "https://slack.com/api/"
          conn.headers["Content-Type"] = "application/json; charset=utf-8"
          conn.headers["Authorization"] = "Bearer #{authorization_token}"
        end
    end

    def views_open(trigger_id:, view:)
      ApiResponse.new { client.post("views.open", { trigger_id: trigger_id, view: view }.to_json) }
    end

    def views_update(view_id:, view:)
      ApiResponse.new { client.post("views.update", { view_id: view_id, view: view }.to_json) }
    end

    def chat_post_message(channel:, text:, blocks:)
      ApiResponse.new { client.post("chat.postMessage", { channel: channel, text: text, blocks: blocks }.to_json) }
    end

    def chat_update(channel:, ts:, text:, blocks:)
      ApiResponse.new { client.post("chat.update", { channel: channel, ts: ts, text: text, blocks: blocks }.to_json) }
    end

    def users_info(user_id:)
      ApiResponse.new { client.post("users.info", { user: user_id }.to_json) }
    end

    def views_publish(user_id:, view:)
      ApiResponse.new { client.post("views.publish", { user_id: user_id, view: view }.to_json) }
    end

    def users_list(cursor: nil, limit: 200, include_locale: nil, team_id: nil)
      args = {}
      args[:cursor] = cursor if cursor
      args[:limit] = limit if limit
      args[:include_locale] = include_locale if include_locale
      args[:team_id] = team_id if team_id
      ApiResponse.new { client.post("users.list", args.to_json) }
    end

    def chat_post_ephemeral(channel:, user:, text:, as_user: nil, attachments: nil, blocks: nil, icon_emoji: nil, icon_url: nil, link_names: nil, parse: nil, thread_ts: nil, username: nil)
      args = {}
      args[:channel] = channel
      args[:user] = user
      args[:text] = text if text
      args[:as_user] = as_user if as_user
      args[:attachments] = attachments if attachments
      args[:blocks] = blocks if blocks
      args[:icon_emoji] = icon_emoji if icon_emoji
      args[:icon_url] = icon_url if icon_url
      args[:link_names] = link_names if link_names
      args[:parse] = parse if parse
      args[:thread_ts] = thread_ts if thread_ts
      args[:username] = username if username
      ApiResponse.new { client.post("chat.postEphemeral", args.to_json) }
    end
  end
end
