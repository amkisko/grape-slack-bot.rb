require "spec_helper"

describe SlackBot::ArgsBuilder do
  describe "#initialize" do
    it "stores the args hash" do
      builder = described_class.new({foo: "bar"})
      expect(builder.instance_variable_get(:@args)).to eq({foo: "bar"})
    end
  end

  describe "#call" do
    it "builds query string from hash" do
      builder = described_class.new({"foo" => "bar", "baz" => "qux"})
      result = builder.call
      expect(result).to eq("foo=bar&baz=qux")
    end

    it "handles empty hash" do
      builder = described_class.new({})
      result = builder.call
      expect(result).to eq("")
    end

    it "handles single key-value pair" do
      builder = described_class.new({"foo" => "bar"})
      result = builder.call
      expect(result).to eq("foo=bar")
    end

    it "URL-encodes values" do
      builder = described_class.new({"foo" => "hello world"})
      result = builder.call
      expect(result).to eq("foo=hello+world")
    end
  end
end
