module SlackBot
  class Schema
    module Responses
      OPERATIONS = %i[open_modal update_modal push_modal publish_view response_action response_url delete_original].freeze

      module Declaration
        def respond_with(mode = nil, **options)
          if mode && (!%i[ack none].include?(mode) || options.any?)
            raise Errors::ConfigurationError.new("Expected :ack or :none without options")
          end

          declaration = [mode || declared_operation(options), options.freeze].freeze
          define_singleton_method(:response_declaration) { declaration }
        end

        def response_declaration
          nil
        end

        private

        def declared_operation(options)
          operations = OPERATIONS & options.keys
          operations.delete(:delete_original) if options.key?(:response_url)
          raise Errors::ConfigurationError.new("Declare exactly one response operation") unless operations.one?

          operations.first
        end
      end

      def self.included(base)
        base.extend Declaration
      end

      def call
        result = resolve_request
        return if result == :halt
        return submission_override(result) if result.is_a?(Hash)

        declaration = self.class.response_declaration
        return result unless declaration

        mode, options = declaration
        case mode
        when :ack then nil
        when :none then result
        else apply_response(mode, options)
        end
      end

      def resolve
        nil
      end

      private

      def resolve_request
        resolve
      end

      def submission_override(result)
        result
      end

      def apply_response(mode, _options)
        raise Errors::ConfigurationError.new("#{mode} is unavailable for #{self.class.name}")
      end
    end
  end
end
