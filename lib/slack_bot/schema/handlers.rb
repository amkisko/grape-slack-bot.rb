module SlackBot
  class Schema
    class SlashCommand < SlackBot::Command
      include Responses
      include ViewOwner
      include SlackResponses

      class_attribute :input_class, instance_accessor: false

      def self.input(klass)
        self.input_class = klass
      end

      private

      def resolve_request
        input = self.class.input_class
        input ? resolve(**input.coerce(args)) : super
      end
    end

    class Event < SlackBot::Event
      include Responses
      include ViewOwner
      include SlackResponses
    end

    class Interaction < SlackBot::Interaction
      include Responses
      include ViewOwner
      include SlackResponses

      private

      def interaction_payload
        payload
      end
    end

    class ViewClosed < Interaction
    end

    class Shortcut < Interaction
    end

    class MessageAction < Interaction
    end

    class Options < SlackBot::MenuOptions
      include Responses

      def value
        params[:value]
      end
    end
  end
end
