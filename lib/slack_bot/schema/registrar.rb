module SlackBot
  class Schema
    class Registrar
      def initialize(config)
        @config = config
      end

      def register(schema)
        schema.registrations.each do |(route, _key), arguments|
          case route
          when :slash_command
            register_slash(*arguments)
          when :block_actions
            @config.block_action(*arguments)
          else
            @config.public_send(route, *arguments)
          end
        end
        @config
      end

      private

      def register_slash(url_token, handler)
        if handler <= SlashCommandGroup
          endpoint = @config.slash_command_endpoint(url_token, handler.default_handler)
          handler.commands.each { |token, command| endpoint.command(token, command) }
        else
          @config.slash_command_endpoint(url_token, handler)
        end
      end
    end
  end
end
