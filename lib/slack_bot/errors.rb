module SlackBot
  module Errors
    class SignatureAuthenticationError < StandardError
    end

    class TeamAuthenticationError < StandardError
    end

    class ChannelAuthenticationError < StandardError
    end

    class UserAuthenticationError < StandardError
    end

    class SlashCommandNotImplemented < StandardError
    end

    class MenuOptionsNotImplemented < StandardError
    end

    class SlackResponseError < StandardError
      attr_reader :error, :data, :payload
      def initialize(error, data: nil, payload: nil)
        @error = error
        @data = data
        @payload = payload
      end
    end

    class OpenModalError < SlackResponseError
    end

    class UpdateModalError < SlackResponseError
    end

    class PublishViewError < SlackResponseError
    end
  end
end
