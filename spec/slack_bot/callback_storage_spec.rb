require "spec_helper"

describe SlackBot::CallbackStorage do
  let(:storage) { Class.new(described_class).new }

  describe "#read" do
    it "raises NotImplementedError" do
      expect { storage.read("key") }.to raise_error(SlackBot::Errors::NotImplementedError, /read must be implemented/)
    end
  end

  describe "#write" do
    it "raises NotImplementedError" do
      expect { storage.write("key", "value", expires_in: 1.hour) }.to raise_error(SlackBot::Errors::NotImplementedError, /write must be implemented/)
    end
  end

  describe "#delete" do
    it "raises NotImplementedError" do
      expect { storage.delete("key") }.to raise_error(SlackBot::Errors::NotImplementedError, /delete must be implemented/)
    end
  end
end
