module SlackBot
  class Schema
    module ViewOwner
      EMPTY_HANDLERS = {}.freeze

      module Declaration
        def interaction_handlers
          EMPTY_HANDLERS
        end

        %w[block_actions view_submission view_closed].each do |type|
          define_method(type) do |handler|
            handlers = interaction_handlers.merge(type => handler).freeze
            define_singleton_method(:interaction_handlers) { handlers }
          end
        end
      end

      def self.included(base)
        base.extend Declaration
      end

      private

      def active_callback
        callback if respond_to?(:callback)
      end

      def new_view_callback
        previous = active_callback
        return unless previous || self.class.interaction_handlers.any?

        raise Errors::UserAuthenticationError.new("User is not authorized") unless current_user

        persist_view_callback(build_view_callback(previous), previous)
      end

      def persist_view_callback(record, previous)
        source_args = previous ? previous.args : (args if respond_to?(:args))
        record.args.raw_args = source_args&.to_s
        raise Errors::SlackApiError.new("Unable to store Slack callback") if record.save == false

        record
      end

      def build_view_callback(previous)
        owner_name = previous&.class_name || self.class.name
        raise Errors::ConfigurationError.new("Register a named view owner") if owner_name.nil?

        channel_id = previous&.channel_id || slack_field("channel_id") || interaction_payload.dig("channel", "id")
        Callback.new(class_name: owner_name, user: current_user, channel_id: channel_id, config: config, payload: previous&.payload)
      end
    end
  end
end
