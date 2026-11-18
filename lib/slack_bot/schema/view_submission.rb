module SlackBot
  class Schema
    class ViewSubmission < Interaction
      VALUE_FIELDS = %w[value selected_option selected_options selected_user selected_users selected_channel selected_channels
        selected_conversation selected_conversations selected_date selected_time selected_date_time rich_text_value].freeze

      def view_state(block_id = nil, action_id = nil)
        values = payload.dig("view", "state", "values") || {}
        return values if block_id.nil?
        return values[block_id.to_s] if action_id.nil?

        field = values.dig(block_id.to_s, action_id.to_s)
        submitted_value(field) if field
      end

      private

      def submitted_value(field)
        value_field = VALUE_FIELDS.find { |name| field.key?(name) }
        case value_field
        when "selected_option" then field.dig("selected_option", "value")
        when "selected_options" then field["selected_options"]&.map { |option| option["value"] }
        when nil then field
        else field[value_field]
        end
      end

      def submission_override(result)
        errors = result[:errors] || result["errors"]
        errors ? {response_action: "errors", errors: errors} : super
      end

      def apply_response(mode, options)
        return super unless mode == :response_action

        operation = options.fetch(:response_action)
        case operation
        when :clear then {response_action: "clear"}
        when :errors then nil
        when :update, :push
          view = render_view(options.fetch(:view))
          record = (operation == :push) ? new_view_callback : active_callback
          {response_action: operation.to_s, view: SlackBot::Interaction.modal_payload(record, view)}
        else
          raise Errors::ConfigurationError.new("Unknown response_action #{operation}")
        end
      end
    end
  end
end
