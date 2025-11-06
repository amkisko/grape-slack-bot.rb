require "spec_helper"

describe SlackBot::Config do
  subject(:config) { described_class.new }

  describe ".current_instance" do
    it "returns a Config instance" do
      expect(described_class.current_instance).to be_a(described_class)
    end

    it "returns the same instance for the same class" do
      instance1 = described_class.current_instance
      instance2 = described_class.current_instance
      expect(instance1).to eq(instance2)
    end
  end

  describe ".configure" do
    it "yields the current instance" do
      expect { |b| described_class.configure(&b) }.to yield_with_args(described_class.current_instance)
    end

    it "allows configuration via block" do
      storage = double("storage")
      described_class.configure do |c|
        c.callback_storage(storage)
      end
      expect(described_class.current_instance.callback_storage_instance).to eq(storage)
    end
  end

  describe "#callback_storage" do
    it "sets callback_storage_instance" do
      storage = double("storage")
      config.callback_storage(storage)
      expect(config.callback_storage_instance).to eq(storage)
    end
  end

  describe "#callback_user_finder" do
    it "sets callback_user_finder_method" do
      finder = ->(id) { User.find(id) }
      config.callback_user_finder(finder)
      expect(config.callback_user_finder_method).to eq(finder)
    end
  end

  describe "#interaction" do
    let(:interaction_class) do
      Class.new do
        def self.name
          "TestInteraction"
        end
      end
    end

    it "registers interaction handler" do
      config.interaction(interaction_class)
      expect(config.find_handler_class(interaction_class.name)).to eq(interaction_class)
    end

    context "with custom handler_name" do
      it "registers with custom name" do
        config.interaction(interaction_class, handler_name: "CustomName")
        expect(config.find_handler_class("CustomName")).to eq(interaction_class)
      end
    end
  end

  describe "#event" do
    let(:event_class) do
      Class.new do
        def self.name
          "TestEvent"
        end
      end
    end

    it "registers event handler" do
      config.event(:app_home_opened, event_class)
      expect(config.find_event_handler(:app_home_opened)).to eq(event_class)
    end

    it "registers handler class" do
      config.event(:app_home_opened, event_class)
      expect(config.find_handler_class(event_class.name)).to eq(event_class)
    end

    context "with custom handler_name" do
      it "registers with custom name" do
        config.event(:app_home_opened, event_class, handler_name: "CustomName")
        expect(config.find_handler_class("CustomName")).to eq(event_class)
      end
    end
  end

  describe "#find_event_handler" do
    let(:event_class) do
      Class.new do
        def self.name
          "TestEvent"
        end
      end
    end

    it "returns nil when event is not registered" do
      expect(config.find_event_handler(:unknown_event)).to be_nil
    end

    it "returns registered event handler" do
      config.event(:app_home_opened, event_class)
      expect(config.find_event_handler(:app_home_opened)).to eq(event_class)
    end
  end

  describe "#slash_command_endpoint" do
    let(:command_class) do
      Class.new do
        def self.name
          "TestCommand"
        end
      end
    end

    it "creates SlashCommandEndpointConfig" do
      endpoint = config.slash_command_endpoint(:game, command_class)
      expect(endpoint).to be_a(SlackBot::SlashCommandEndpointConfig)
      expect(endpoint.url_token).to eq(:game)
    end

    it "registers endpoint in slash_command_endpoints" do
      config.slash_command_endpoint(:game, command_class)
      expect(config.slash_command_endpoints[:game]).to be_a(SlackBot::SlashCommandEndpointConfig)
    end

    it "yields to block for configuration" do
      yielded_endpoint = nil
      config.slash_command_endpoint(:game, command_class) do |endpoint|
        yielded_endpoint = endpoint
      end
      expect(yielded_endpoint).to be_a(SlackBot::SlashCommandEndpointConfig)
    end
  end

  describe "#find_slash_command_config" do
    let(:command_class) do
      Class.new do
        def self.name
          "TestCommand"
        end
      end
    end

    before do
      endpoint = config.slash_command_endpoint(:game, command_class)
      endpoint.command(:start, command_class)
    end

    it "returns command config when found" do
      result = config.find_slash_command_config(:game, "/game", "start test")
      expect(result).to be_a(SlackBot::SlashCommandConfig)
    end

    it "returns endpoint config when command not found" do
      result = config.find_slash_command_config(:game, "/game", "test")
      expect(result).to be_a(SlackBot::SlashCommandEndpointConfig)
    end

    it "returns nil when endpoint not found" do
      result = config.find_slash_command_config(:unknown, "/unknown", "test")
      expect(result).to be_nil
    end
  end

  describe "#menu_options" do
    let(:menu_options_class) { Class.new }

    it "registers menu options handler" do
      config.menu_options(:test_action, menu_options_class)
      expect(config.find_menu_options(:test_action)).to eq(menu_options_class)
    end
  end

  describe "#find_menu_options" do
    let(:menu_options_class) { Class.new }

    it "returns nil when action_id is not registered" do
      expect(config.find_menu_options(:unknown)).to be_nil
    end

    it "returns registered menu options class" do
      config.menu_options(:test_action, menu_options_class)
      expect(config.find_menu_options(:test_action)).to eq(menu_options_class)
    end
  end

  describe "#handler_class" do
    let(:handler_class) { Class.new }

    it "registers handler class" do
      config.handler_class("TestClass", handler_class)
      expect(config.find_handler_class("TestClass")).to eq(handler_class)
    end
  end

  describe "#find_handler_class" do
    let(:handler_class) { Class.new }

    it "returns registered handler class" do
      config.handler_class("TestClass", handler_class)
      expect(config.find_handler_class("TestClass")).to eq(handler_class)
    end

    it "raises HandlerClassNotFound when not found" do
      expect { config.find_handler_class("UnknownClass") }.to raise_error(SlackBot::Errors::HandlerClassNotFound) do |error|
        expect(error.class_name).to eq("UnknownClass")
        expect(error.handler_classes).to be_a(Hash)
      end
    end
  end

  describe "#event" do
    let(:event_class) do
      Class.new do
        def self.name
          "TestEvent"
        end
      end
    end

    it "registers event handler" do
      config.event(:message, event_class)
      expect(config.event_handlers[:message]).to eq(event_class)
    end

    it "registers handler class" do
      config.event(:message, event_class)
      expect(config.find_handler_class("TestEvent")).to eq(event_class)
    end

    context "with custom handler_name" do
      it "registers with custom handler name" do
        config.event(:message, event_class, handler_name: "CustomEvent")
        expect(config.find_handler_class("CustomEvent")).to eq(event_class)
      end
    end
  end

  describe "#event_handlers" do
    it "returns empty hash by default" do
      expect(config.event_handlers).to eq({})
    end

    it "returns registered event handlers" do
      event_class = Class.new
      config.event(:message, event_class)
      expect(config.event_handlers[:message]).to eq(event_class)
    end
  end

  describe "#find_event_handler" do
    let(:event_class) do
      Class.new do
        def self.name
          "TestEvent"
        end
      end
    end

    it "returns registered event handler" do
      config.event(:message, event_class)
      expect(config.find_event_handler(:message)).to eq(event_class)
    end

    it "returns nil when not found" do
      expect(config.find_event_handler(:unknown)).to be_nil
    end
  end
end

describe SlackBot::SlashCommandEndpointConfig do
  let(:config) { SlackBot::Config.new }
  let(:command_class) do
    Class.new do
      def self.name
        "TestCommand"
      end
    end
  end

  describe "#initialize" do
    subject(:endpoint) do
      described_class.new(
        :game,
        config: config,
        command_klass: command_class
      )
    end

    it "sets url_token" do
      expect(endpoint.url_token).to eq(:game)
    end

    it "sets command_klass" do
      expect(endpoint.command_klass).to eq(command_class)
    end

    it "sets config" do
      expect(endpoint.config).to eq(config)
    end

    it "registers handler class when command_klass is provided" do
      endpoint
      expect(config.find_handler_class(command_class.name)).to eq(command_class)
    end

    context "when command_klass is nil" do
      subject(:endpoint) do
        described_class.new(
          :game,
          config: config,
          command_klass: nil
        )
      end

      it "does not register handler class" do
        endpoint
        expect { config.find_handler_class("TestCommand") }.to raise_error(SlackBot::Errors::HandlerClassNotFound)
      end
    end

    context "with custom handler_name" do
      subject(:endpoint) do
        described_class.new(
          :game,
          config: config,
          command_klass: command_class,
          handler_name: "CustomHandler"
        )
      end

      it "registers with custom handler name" do
        endpoint
        expect(config.find_handler_class("CustomHandler")).to eq(command_class)
      end
    end
  end

  describe "#command" do
    let(:endpoint) do
      described_class.new(
        :game,
        config: config,
        command_klass: command_class
      )
    end
    let(:subcommand_class) do
      Class.new do
        def self.name
          "SubCommand"
        end
      end
    end

    it "creates SlashCommandConfig" do
      command_config = endpoint.command(:start, subcommand_class)
      expect(command_config).to be_a(SlackBot::SlashCommandConfig)
      expect(command_config.token).to eq(:start)
    end

    it "registers command in command_configs" do
      endpoint.command(:start, subcommand_class)
      expect(endpoint.command_configs[:start]).to be_a(SlackBot::SlashCommandConfig)
    end

    it "yields to block for configuration" do
      yielded_config = nil
      endpoint.command(:start, subcommand_class) do |command|
        yielded_config = command
      end
      expect(yielded_config).to be_a(SlackBot::SlashCommandConfig)
    end
  end

  describe "#find_command_config" do
    let(:endpoint) do
      described_class.new(
        :game,
        config: config,
        command_klass: command_class
      )
    end
    let(:subcommand_class) do
      Class.new do
        def self.name
          "SubCommand"
        end
      end
    end

    before do
      endpoint.command(:start, subcommand_class)
    end

    it "finds command config by text" do
      result = endpoint.find_command_config("start test")
      expect(result).to be_a(SlackBot::SlashCommandConfig)
      expect(result.token).to eq(:start)
    end

    it "returns nil when command not found" do
      result = endpoint.find_command_config("unknown test")
      expect(result).to be_nil
    end
  end

  describe "#full_token" do
    let(:endpoint) do
      described_class.new(
        :game,
        config: config,
        command_klass: command_class
      )
    end

    it "returns empty string" do
      expect(endpoint.full_token).to eq("")
    end
  end
end

describe SlackBot::SlashCommandConfig do
  let(:config) { SlackBot::Config.new }
  let(:endpoint) { SlackBot::SlashCommandEndpointConfig.new(:game, config: config) }
  let(:command_class) do
    Class.new do
      def self.name
        "TestCommand"
      end
    end
  end

  subject(:command_config) do
    described_class.new(
      command_klass: command_class,
      token: :start,
      endpoint: endpoint
    )
  end

  describe ".delimiter" do
    it "returns space" do
      expect(described_class.delimiter).to eq(" ")
    end
  end

  describe "#initialize" do
    it "sets command_klass" do
      expect(command_config.command_klass).to eq(command_class)
    end

    it "sets token" do
      expect(command_config.token).to eq(:start)
    end

    it "sets endpoint" do
      expect(command_config.endpoint).to eq(endpoint)
    end

    it "registers in endpoint routes" do
      expect(endpoint.routes[command_config.full_token]).to eq(command_config)
    end
  end

  describe "#argument_command" do
    let(:subcommand_class) { Class.new }

    it "creates nested SlashCommandConfig" do
      arg_config = command_config.argument_command(:password, subcommand_class)
      expect(arg_config).to be_a(SlackBot::SlashCommandConfig)
      expect(arg_config.token).to eq(:password)
    end

    it "includes parent in parent_configs" do
      arg_config = command_config.argument_command(:password, subcommand_class)
      expect(arg_config.parent_configs).to include(command_config)
    end

    it "yields to block for configuration" do
      yielded_config = nil
      arg_config = command_config.argument_command(:password, subcommand_class) do |config|
        yielded_config = config
      end
      expect(yielded_config).to eq(arg_config)
    end

    it "returns same config on multiple calls" do
      arg_config1 = command_config.argument_command(:password, subcommand_class)
      arg_config2 = command_config.argument_command(:password, subcommand_class)
      expect(arg_config1).to eq(arg_config2)
    end
  end

  describe "#find_argument_command_config" do
    let(:subcommand_class) { Class.new }

    before do
      command_config.argument_command(:password, subcommand_class)
    end

    it "finds argument command config" do
      result = command_config.find_argument_command_config(:password)
      expect(result).to be_a(SlackBot::SlashCommandConfig)
      expect(result.token).to eq(:password)
    end

    it "returns nil when not found" do
      result = command_config.find_argument_command_config(:unknown)
      expect(result).to be_nil
    end
  end

  describe "#full_token" do
    it "returns token when no parent configs" do
      expect(command_config.full_token).to eq("start")
    end

    context "with parent configs" do
      let(:parent_config) do
        described_class.new(
          command_klass: command_class,
          token: :game,
          endpoint: endpoint
        )
      end

      before do
        command_config.parent_configs = [parent_config]
      end

      it "joins parent and current tokens" do
        expect(command_config.full_token).to eq("game start")
      end
    end
  end

  describe "#url_token" do
    it "returns endpoint url_token" do
      expect(command_config.url_token).to eq(:game)
    end
  end
end
