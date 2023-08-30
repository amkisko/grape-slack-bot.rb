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

  describe '.log_input' do
    context 'when enabled' do
      before { described_class.enabled = true }
      it 'logs the message' do
        expect(described_class.logger).to receive(:info).with('>>> test')
        described_class.log_input('test')
      end
    end

    context 'when disabled' do
      before { described_class.enabled = false }
      it 'does not log the message' do
        expect(described_class.logger).not_to receive(:info)
        described_class.log_input('test')
      end
    end
  end

  describe '.log_output' do
    context 'when enabled' do
      before { described_class.enabled = true }
      it 'logs the message' do
        expect(described_class.logger).to receive(:info).with('<<< test')
        described_class.log_output('test')
      end
    end

    context 'when disabled' do
      before { described_class.enabled = false }
      it 'does not log the message' do
        expect(described_class.logger).not_to receive(:info)
        described_class.log_output('test')
      end
    end
  end

  describe '.log_check' do
    context 'when enabled' do
      before { described_class.enabled = true }
      it 'logs the message' do
        expect(described_class.logger).to receive(:info).with('!!! test')
        described_class.log_check('test')
      end
    end

    context 'when disabled' do
      before { described_class.enabled = false }
      it 'does not log the message' do
        expect(described_class.logger).not_to receive(:info)
        described_class.log_check('test')
      end
    end
  end
end
