# frozen_string_literal: true

module SlackBot
  class Schema
    class BlockActions < Interaction
      class_attribute :action_handlers, instance_accessor: false, default: {}.freeze

      def self.action(action_id, args: {}, with: action_id.to_sym)
        self.action_handlers = action_handlers.merge(action_id.to_s => [with, args.dup.freeze].freeze).freeze
      end

      def resolve
        handlers = self.class.action_handlers
        return if handlers.empty?

        matched = false
        actions&.each do |action|
          destination, extractors = handlers[action["action_id"]]
          next unless destination

          matched = true
          result = run_action(destination, extractors, action)
          return result if result == :halt || result.is_a?(Hash)
        end
        :halt unless matched
      end

      private

      def run_action(destination, extractors, action)
        arguments = extractors.transform_values { |source| extract_argument(source, action) }
        if destination.is_a?(Class)
          destination.new(**arguments).call
        else
          send(destination, **arguments)
        end
      end

      def extract_argument(source, action)
        case source
        when :selected_option_value then action.dig("selected_option", "value")
        when :selected_option_values then action["selected_options"]&.map { |option| option["value"] }
        else source.respond_to?(:call) ? source.call(action) : action[source.to_s]
        end
      end
    end
  end
end
