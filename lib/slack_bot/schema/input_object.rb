module SlackBot
  class Schema
    class InputObject
      COERCERS = {
        String => ->(value) { String(value) },
        Integer => ->(value) { Integer(value, 10) },
        Float => ->(value) { Float(value) }
      }.freeze

      class_attribute :arguments, instance_accessor: false, default: {}.freeze

      def self.argument(name, type = String, required: false, default: nil)
        self.arguments = arguments.merge(name.to_sym => [type, required, default].freeze).freeze
      end

      def self.coerce(args)
        arguments.each_with_object({}) do |(name, (type, required, default)), values|
          raw = args[name]
          value = raw.nil? ? default : coerce_argument(raw, type, name)
          raise Errors::InvalidPayloadError.new("Missing argument #{name}") if required && value.nil?

          values[name] = value
        end
      end

      def self.coerce_argument(value, type, name)
        COERCERS.fetch(type, type).call(value)
      rescue ArgumentError, TypeError, RangeError
        raise Errors::InvalidPayloadError.new("Invalid argument #{name}"), cause: nil
      end

      private_class_method :coerce_argument
    end
  end
end
