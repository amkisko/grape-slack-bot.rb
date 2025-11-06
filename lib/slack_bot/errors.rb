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

    class InteractionClassNotImplemented < SlackBot::Error
      attr_reader :class_name
      def initialize(class_name)
        @class_name = class_name
      end
    end

    class ViewClassNotImplemented < SlackBot::Error
      attr_reader :class_name
      def initialize(class_name)
        @class_name = class_name
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

    class CallbackUserMismatchError < SlackBot::Error
    end

    class InvalidPayloadError < SlackBot::Error
    end

    class SlackApiError < SlackBot::Error
    end

    class UnknownActionTypeError < SlackBot::Error
      attr_reader :action_type
      def initialize(action_type)
        @action_type = action_type
        super("Unknown action type: #{action_type}")
      end
    end

    class NotImplementedError < SlackBot::Error
    end
  end
end
