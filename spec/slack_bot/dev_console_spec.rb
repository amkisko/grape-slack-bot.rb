require "spec_helper"

describe SlackBot::DevConsole do
  let(:logger) { instance_double(SlackBot::Logger) }
  before do
    described_class.enabled = true
    described_class.logger = logger
  end

  describe ".enabled=" do
    it "sets the enabled value" do
      expect { described_class.enabled = false }.to change(described_class, :enabled?).from(true).to(false)
    end
  end

  describe ".logger=" do
    let(:new_logger) { instance_double(SlackBot::Logger) }
    after { described_class.logger = logger }
    it "sets the logger" do
      expect { described_class.logger = new_logger }.to change(described_class, :logger).from(logger).to(new_logger)
    end
  end

  describe ".log" do
    context "when enabled" do
      before { described_class.enabled = true }
      it "logs the message" do
        expect(described_class.logger).to receive(:info).with("test")
        described_class.log("test")
      end
    end

    context "when disabled" do
      before { described_class.enabled = false }
      it "does not log the message" do
        expect(described_class.logger).not_to receive(:info)
        described_class.log("test")
      end
    end
  end

  describe ".log_input" do
    context "when enabled" do
      before { described_class.enabled = true }
      it "logs the message" do
        expect(described_class.logger).to receive(:info).with(">>> test")
        described_class.log_input("test")
      end
    end

    context "when disabled" do
      before { described_class.enabled = false }
      it "does not log the message" do
        expect(described_class.logger).not_to receive(:info)
        described_class.log_input("test")
      end
    end
  end

  describe ".log_output" do
    context "when enabled" do
      before { described_class.enabled = true }
      it "logs the message" do
        expect(described_class.logger).to receive(:info).with("<<< test")
        described_class.log_output("test")
      end
    end

    context "when disabled" do
      before { described_class.enabled = false }
      it "does not log the message" do
        expect(described_class.logger).not_to receive(:info)
        described_class.log_output("test")
      end
    end
  end

  describe ".log_check" do
    context "when enabled" do
      before { described_class.enabled = true }
      it "logs the message" do
        expect(described_class.logger).to receive(:info).with("!!! test")
        described_class.log_check("test")
      end
    end

    context "when disabled" do
      before { described_class.enabled = false }
      it "does not log the message" do
        expect(described_class.logger).not_to receive(:info)
        described_class.log_check("test")
      end
    end
  end

  describe ".log with block" do
    context "when enabled" do
      before { described_class.enabled = true }
      it "logs the message from block" do
        expect(described_class.logger).to receive(:info).with("block message")
        described_class.log { "block message" }
      end
    end

    context "when disabled" do
      before { described_class.enabled = false }
      it "does not execute block" do
        expect(described_class.logger).not_to receive(:info)
        block_executed = false
        described_class.log { block_executed = true }
        expect(block_executed).to be false
      end
    end
  end

  describe ".log_input with block" do
    context "when enabled" do
      before { described_class.enabled = true }
      it "logs the message from block with prefix" do
        expect(described_class.logger).to receive(:info).with(">>> block message")
        described_class.log_input { "block message" }
      end
    end
  end

  describe ".log_output with block" do
    context "when enabled" do
      before { described_class.enabled = true }
      it "logs the message from block with prefix" do
        expect(described_class.logger).to receive(:info).with("<<< block message")
        described_class.log_output { "block message" }
      end
    end
  end

  describe ".log_check with block" do
    context "when enabled" do
      before { described_class.enabled = true }
      it "logs the message from block with prefix" do
        expect(described_class.logger).to receive(:info).with("!!! block message")
        described_class.log_check { "block message" }
      end
    end
  end

  describe ".logger" do
    it "returns default logger when not set" do
      described_class.instance_variable_set(:@logger, nil)
      expect(described_class.logger).to be_a(SlackBot::Logger)
    end
  end
end
