module SlackBot
  class Logger
    def info(*args, **kwargs)
      puts args, kwargs
    end
  end
  class DevConsole
    def self.enabled=(value)
      @enabled = value
    end

    def self.enabled?
      @enabled
    end

    def self.logger=(value)
      @logger = value
    end

    def self.logger
      @logger ||= Logger.new
    end

    def self.log(message = nil, &block)
      return unless enabled?

      message = yield if block_given?
      logger.info(message)
    end

    def self.log_input(message = nil, &block)
      message = yield if block_given?
      log(">>> #{message}")
    end

    def self.log_output(message = nil, &block)
      message = yield if block_given?
      log("<<< #{message}")
    end

    def self.log_check(message = nil, &block)
      message = yield if block_given?
      log("!!! #{message}")
    end
  end
end

require 'spec_helper'

describe SlackBot::DevConsole do
  let(:logger) { instance_double(SlackBot::Logger) }
  before do
    described_class.enabled = true
    described_class.logger = logger
  end

  describe '.enabled=' do
    it 'sets the enabled value' do
      expect { described_class.enabled = false }.to change(described_class, :enabled?).from(true).to(false)
    end
  end

  describe '.logger=' do
    let(:new_logger) { instance_double(SlackBot::Logger) }
    after { described_class.logger = logger }
    it 'sets the logger' do
      expect { described_class.logger = new_logger }.to change(described_class, :logger).from(logger).to(new_logger)
    end
  end

  describe '.log' do
    context 'when enabled' do
      before { described_class.enabled = true }
      it 'logs the message' do
        expect(described_class.logger).to receive(:info).with('test')
        described_class.log('test')
      end
    end

    context 'when disabled' do
      before { described_class.enabled = false }
      it 'does not log the message' do
        expect(described_class.logger).not_to receive(:info)
        described_class.log('test')
      end
    end
  end
end
