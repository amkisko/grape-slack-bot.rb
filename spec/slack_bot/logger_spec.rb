require "spec_helper"

describe SlackBot::Logger do
  subject(:logger) { described_class.new }

  describe "#info" do
    it "prints the args" do
      expect { logger.info("test") }.to output(%(["test"]\n)).to_stdout
    end

    it "prints the kwargs" do
      expect { logger.info(test: "test") }.to output(%({test: "test"}\n)).to_stdout
    end

    it "handles multiple args" do
      expect { logger.info("arg1", "arg2") }.to output(%(["arg1", "arg2"]\n)).to_stdout
    end

    it "handles both args and kwargs" do
      expect { logger.info("arg", key: "value") }.to output(%(["arg"]\n{key: "value"}\n)).to_stdout
    end
  end

  describe "#error" do
    it "prints the args" do
      expect { logger.error("error message") }.to output(%(["error message"]\n)).to_stdout
    end
  end

  describe "#warn" do
    it "prints the args" do
      expect { logger.warn("warning message") }.to output(%(["warning message"]\n)).to_stdout
    end
  end

  describe "#debug" do
    it "prints the args" do
      expect { logger.debug("debug message") }.to output(%(["debug message"]\n)).to_stdout
    end
  end
end
