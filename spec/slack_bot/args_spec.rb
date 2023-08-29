require 'spec_helper'

describe SlackBot::Args do
  let(:args) { SlackBot::Args.new }
  let(:raw_args) { "foo=bar&baz=qux" }

  describe "#raw_args=" do
    it "parses raw args" do
      args.raw_args = raw_args
      expect(args.args).to eq({ "foo" => "bar", "baz" => "qux" }.with_indifferent_access)
    end
  end

  describe "#to_s" do
    it "builds args" do
      args.raw_args = raw_args
      expect(args.to_s).to eq(raw_args)
    end
  end

  describe "#merge" do
    it "merges args" do
      args.raw_args = raw_args
      expect(args.merge(foo: "baz").args).to eq({ "foo" => "baz", "baz" => "qux" }.with_indifferent_access)
    end
  end

  describe "#except" do
    it "removes args" do
      args.raw_args = raw_args
      expect(args.except(:foo).args).to eq({ "baz" => "qux" }.with_indifferent_access)
    end
  end
end
