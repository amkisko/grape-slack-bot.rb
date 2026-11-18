module SlackBot
  class Schema
    module SlackResponses
      private

      def apply_response(mode, options)
        case mode
        when :open_modal, :push_modal, :update_modal, :publish_view
          send_view(mode, render_view(options.fetch(mode)))
        when :response_url, :delete_original
          send_message(options)
        else
          super
        end
        nil
      end

      def interaction_payload
        params
      end

      def slack_field(name)
        interaction_payload[name] || interaction_payload[name.to_sym]
      end

      def send_view(mode, view)
        case mode
        when :open_modal, :push_modal
          trigger_id = require_slack_field(slack_field("trigger_id"), "trigger_id")
          SlackBot::Interaction.public_send(mode, callback: new_view_callback, trigger_id: trigger_id, view: view)
        when :update_modal
          update_rendered_modal(view)
        when :publish_view
          publish_rendered_view(view)
        end
      end

      def update_rendered_modal(view)
        source = interaction_payload["view"] || {}
        SlackBot::Interaction.update_modal(callback: active_callback,
          view_id: require_slack_field(source["id"], "view.id"), view: view, hash: source["hash"])
      end

      def publish_rendered_view(view)
        user_id = slack_field("user_id") || interaction_payload.dig("user", "id") ||
          params.dig("event", "user") || params.dig(:event, :user)
        SlackBot::Interaction.publish_view(user_id: require_slack_field(user_id, "user"), view: view,
          callback: active_callback || new_view_callback)
      end

      def send_message(options)
        url = require_slack_field(response_destination, "response_url")
        response = ApiClient.response_url_post(url, **response_message(options))
        raise Errors::SlackApiError.new("Slack did not accept the response message") unless response.ok?
      end

      def response_destination
        url = slack_field("response_url")
        return url if url.present?

        urls = slack_field("response_urls") || interaction_payload.dig("view", "response_urls")
        entry = urls.first if urls.is_a?(Array) && urls.one?
        entry["response_url"] if entry.is_a?(Hash)
      end

      def response_message(options)
        message = options.except(:response_url)
        message[:response_type] = options[:response_url].to_s if options.key?(:response_url)
        message[:blocks] = render_view(message[:blocks]) if message[:blocks].is_a?(Symbol)
        message
      end

      def require_slack_field(value, name)
        return value if value.present?

        raise Errors::InvalidPayloadError.new("Missing Slack field #{name}")
      end
    end
  end
end
