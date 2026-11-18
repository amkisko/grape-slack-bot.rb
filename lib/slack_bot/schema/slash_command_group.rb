module SlackBot
  class Schema
    class SlashCommandGroup
      class_attribute :default_handler, :commands, instance_accessor: false
      self.commands = {}.freeze

      def self.default_command(handler)
        self.default_handler = handler
      end

      def self.command(token, handler)
        self.commands = commands.merge(token.to_sym => handler).freeze
      end
    end
  end
end
