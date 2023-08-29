require 'active_support/core_ext/object'

module SlackBot
  class Config
    def self.current_instance
      @@current_instances ||= {}
      @@current_instances[self.name] ||= self.new
    end

    def self.configure(&block)
      current_instance.instance_eval(&block)
    end

    attr_reader :callback_storage_instance
    def callback_storage(klass)
      @callback_storage_instance = klass
    end

    attr_reader :callback_user_finder_method
    def callback_user_finder(method_lambda)
      @callback_user_finder_method = method_lambda
    end

    def event_handlers
      @event_handlers ||= {}
    end

    def event(event_type, event_klass)
      event_handlers[event_type.to_sym] = event_klass
    end

    def find_event_handler(event_type)
      event_handlers[event_type.to_sym]
    end

    def slash_command_endpoint(url_token, command_klass = nil, &block)
      @slash_command_endpoints ||= {}
      @slash_command_endpoints[url_token.to_sym] ||=
        begin
          endpoint =
            SlashCommandEndpoint.new(url_token, command_klass: command_klass, config: self)
          endpoint.instance_eval(&block) if block_given?
          endpoint
        end
    end

    def slash_command_endpoints
      @slash_command_endpoints ||= {}
    end

    def find_slash_command_config(url_token, command, text)
      endpoint_config = slash_command_endpoints[url_token.to_sym]
      return if endpoint_config.blank?

      endpoint_config.find_command_config(text) || endpoint_config
    end

    def menu_options(action_id, klass)
      @menu_options ||= {}
      @menu_options[action_id.to_sym] = klass
    end

    def find_menu_options(action_id)
      @menu_options ||= {}
      @menu_options[action_id.to_sym]
    end

    def handler_class(class_name, klass)
      @handler_classes ||= {}
      @handler_classes[class_name.to_sym] = klass
    end

    def find_handler_class(class_name)
      @handler_classes ||= {}
      @handler_classes[class_name.to_sym]
    end
  end

  class SlashCommandEndpoint
    attr_reader :url_token, :command_klass, :routes, :config
    def initialize(url_token, config:, command_klass: nil, routes: {})
      @url_token = url_token
      @command_klass = command_klass
      @routes = routes
      @config = config

      config.handler_class(command_klass.name, command_klass) if command_klass.present?
    end

    def command(command_token, command_klass, &block)
      @command_configs ||= {}
      @command_configs[command_token.to_sym] ||=
        begin
          command =
            SlashCommandConfig.new(
              command_klass: command_klass,
              token: command_token,
              endpoint: self
            )
          command.instance_eval(&block) if block_given?
          command
        end
    end

    def command_configs
      @command_configs ||= {}
    end

    def find_command_config(text)
      route_key = text.scan(/^(#{routes.keys.join("|")})(?:\s|$)/).flatten.first
      return if route_key.blank?

      routes[route_key]
    end

    def full_token
      ""
    end
  end

  class SlashCommandConfig
    def self.delimiter
      " "
    end

    attr_accessor :command_klass, :token, :parent_configs, :endpoint
    def initialize(command_klass:, token:, endpoint:, config:, parent_configs: [])
      @command_klass = command_klass
      @token = token
      @parent_configs = parent_configs || []
      @endpoint = endpoint

      endpoint.routes[full_token] = self
      endpoint.config.handler_class(command_klass.name, command_klass)
    end

    def argument_command(argument_token, klass = nil, &block)
      @argument_command_configs ||= {}
      @argument_command_configs[argument_token.to_sym] ||=
        SlashCommandConfig.new(
          command_klass: command_klass,
          token: argument_token,
          parent_configs: [self] + (parent_configs || []),
          endpoint: endpoint
        )

      command_config = @argument_command_configs[argument_token.to_sym]
      command_config.instance_eval(&block) if block_given?

      command_config
    end

    def find_argument_command_config(argument_token)
      @argument_command_configs ||= {}
      @argument_command_configs[argument_token.to_sym]
    end

    def full_token
      [parent_configs.map(&:token), token].flatten.compact.join(
        self.class.delimiter
      )
    end

    def url_token
      endpoint.url_token
    end
  end
end
