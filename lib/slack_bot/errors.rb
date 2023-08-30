module SlackBot
  module Errors
    class SignatureAuthenticationError < SlackBot::Error
    end

    class TeamAuthenticationError < SlackBot::Error
    end

    class ChannelAuthenticationError < SlackBot::Error
    end

    class UserAuthenticationError < SlackBot::Error
    end

    class SlashCommandNotImplemented < SlackBot::Error
    end

    class MenuOptionsNotImplemented < SlackBot::Error
    end

    class CallbackNotFound < SlackBot::Error
    end

    class SlackResponseError < SlackBot::Error
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
