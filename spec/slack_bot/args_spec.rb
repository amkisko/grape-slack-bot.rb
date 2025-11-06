require "spec_helper"

describe SlackBot::Args do
  let(:args) { SlackBot::Args.new }
  let(:raw_args) { "foo=bar&baz=qux" }

  describe "#initialize" do
    it "initializes with empty args hash" do
      expect(args.args).to eq({})
    end

    it "accepts custom builder and parser" do
      custom_builder = Class.new(SlackBot::ArgsBuilder)
      custom_parser = Class.new(SlackBot::ArgsParser)
      args = described_class.new(builder: custom_builder, parser: custom_parser)
      expect(args.instance_variable_get(:@builder)).to eq(custom_builder)
      expect(args.instance_variable_get(:@parser)).to eq(custom_parser)
    end
  end

  describe "#[]" do
    it "returns value for key" do
      args.raw_args = raw_args
      expect(args["foo"]).to eq("bar")
      expect(args["baz"]).to eq("qux")
    end

    it "returns nil for missing key" do
      expect(args["missing"]).to be_nil
    end
  end

  describe "#[]=" do
    it "sets value for key" do
      args["new_key"] = "new_value"
      expect(args["new_key"]).to eq("new_value")
    end
  end

  describe "#raw_args=" do
    it "parses raw args" do
      args.raw_args = raw_args
      expect(args.args).to eq({"foo" => "bar", "baz" => "qux"}.with_indifferent_access)
    end

    it "handles empty string" do
      args.raw_args = ""
      expect(args.args).to eq({})
    end

    it "handles nil" do
      args.raw_args = nil
      expect(args.args).to eq({})
    end
  end

  describe "#to_s" do
    it "builds args" do
      args.raw_args = raw_args
      expect(args.to_s).to eq(raw_args)
    end

    it "handles empty args" do
      expect(args.to_s).to eq("")
    end
  end

  describe "#merge" do
    it "merges args" do
      args.raw_args = raw_args
      merged = args.merge(foo: "baz")
      expect(merged.args).to eq({"foo" => "baz", "baz" => "qux"}.with_indifferent_access)
      expect(merged).to be_a(SlackBot::Args)
      expect(merged).not_to eq(args)
    end

    it "does not modify original args" do
      args.raw_args = raw_args
      args.merge(foo: "baz")
      expect(args["foo"]).to eq("bar")
    end
  end

  describe "#except" do
    it "removes args" do
      args.raw_args = raw_args
      excepted = args.except(:foo)
      expect(excepted.args).to eq({"baz" => "qux"}.with_indifferent_access)
      expect(excepted).to be_a(SlackBot::Args)
      expect(excepted).not_to eq(args)
    end

    it "does not modify original args" do
      args.raw_args = raw_args
      args.except(:foo)
      expect(args["foo"]).to eq("bar")
    end

    it "handles multiple keys" do
      args.raw_args = "foo=bar&baz=qux&quux=corge"
      excepted = args.except(:foo, :baz)
      expect(excepted.args).to eq({"quux" => "corge"}.with_indifferent_access)
    end
  end
end
