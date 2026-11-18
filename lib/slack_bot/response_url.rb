require "uri"

module SlackBot
  module ResponseUrl
    HOSTS = %w[hooks.slack.com hooks.slack-gov.com].freeze
    PATH = %r{\A/(?:actions|services|app(?:-actions)?)/[a-zA-Z0-9_/-]+\z}

    Reply = Struct.new(:status) do
      def ok?
        (200...300).cover?(status)
      end
    end

    module_function

    def post(url, message)
      destination = validate(url)
      response = client.post(destination, JSON.generate(message))
      Reply.new(response.status)
    rescue Faraday::Error
      raise Errors::SlackApiError.new("Slack response URL request failed"), cause: nil
    end

    def validate(url)
      uri = URI.parse(url) if url.is_a?(String)
      return uri if uri.is_a?(URI::HTTPS) && valid_destination?(uri)

      raise Errors::SlackApiError.new("Invalid Slack response URL")
    rescue URI::InvalidURIError
      raise Errors::SlackApiError.new("Invalid Slack response URL"), cause: nil
    end

    def valid_destination?(uri)
      HOSTS.include?(uri.host) && uri.port == 443 && PATH.match?(uri.path) &&
        uri.userinfo.nil? && uri.query.nil? && uri.fragment.nil?
    end

    def client
      Faraday.new(headers: {"Content-Type" => "application/json; charset=utf-8"},
        request: {timeout: 2, open_timeout: 1})
    end
  end
end
