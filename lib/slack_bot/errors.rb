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

    class HandlerClassNotFound < SlackBot::Error
      attr_reader :class_name, :handler_classes
      def initialize(class_name, handler_classes:)
        @class_name = class_name
        @handler_classes = handler_classes

        super("Handler class not found for #{class_name}")
      end
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
