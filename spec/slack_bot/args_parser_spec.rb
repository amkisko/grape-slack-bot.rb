require "spec_helper"

describe SlackBot::ArgsParser do
  describe "#initialize" do
    it "stores the args string" do
      parser = described_class.new("foo=bar")
      expect(parser.instance_variable_get(:@args)).to eq("foo=bar")
    end
  end

  describe "#call" do
    it "parses query string into hash" do
      parser = described_class.new("foo=bar&baz=qux")
      result = parser.call
      expect(result).to eq({"foo" => "bar", "baz" => "qux"})
    end

    it "handles empty string" do
      parser = described_class.new("")
      result = parser.call
      expect(result).to eq({})
    end

    it "handles single key-value pair" do
      parser = described_class.new("foo=bar")
      result = parser.call
      expect(result).to eq({"foo" => "bar"})
    end

    it "handles URL-encoded values" do
      parser = described_class.new("foo=hello%20world")
      result = parser.call
      expect(result).to eq({"foo" => "hello world"})
    end
  end
end
