require "spec_helper"

describe SlackBot::Errors do
  describe "error inheritance" do
    it "all errors inherit from SlackBot::Error" do
      expect(SlackBot::Errors::SignatureAuthenticationError.superclass).to eq(SlackBot::Error)
      expect(SlackBot::Errors::TeamAuthenticationError.superclass).to eq(SlackBot::Error)
      expect(SlackBot::Errors::ChannelAuthenticationError.superclass).to eq(SlackBot::Error)
      expect(SlackBot::Errors::UserAuthenticationError.superclass).to eq(SlackBot::Error)
      expect(SlackBot::Errors::SlashCommandNotImplemented.superclass).to eq(SlackBot::Error)
      expect(SlackBot::Errors::MenuOptionsNotImplemented.superclass).to eq(SlackBot::Error)
      expect(SlackBot::Errors::CallbackNotFound.superclass).to eq(SlackBot::Error)
      expect(SlackBot::Errors::HandlerClassNotFound.superclass).to eq(SlackBot::Error)
      expect(SlackBot::Errors::InteractionClassNotImplemented.superclass).to eq(SlackBot::Error)
      expect(SlackBot::Errors::ViewClassNotImplemented.superclass).to eq(SlackBot::Error)
      expect(SlackBot::Errors::SlackResponseError.superclass).to eq(SlackBot::Error)
      expect(SlackBot::Errors::OpenModalError.superclass).to eq(SlackBot::Errors::SlackResponseError)
      expect(SlackBot::Errors::UpdateModalError.superclass).to eq(SlackBot::Errors::SlackResponseError)
      expect(SlackBot::Errors::PublishViewError.superclass).to eq(SlackBot::Errors::SlackResponseError)
      expect(SlackBot::Errors::CallbackUserMismatchError.superclass).to eq(SlackBot::Error)
      expect(SlackBot::Errors::InvalidPayloadError.superclass).to eq(SlackBot::Error)
      expect(SlackBot::Errors::SlackApiError.superclass).to eq(SlackBot::Error)
      expect(SlackBot::Errors::UnknownActionTypeError.superclass).to eq(SlackBot::Error)
      expect(SlackBot::Errors::NotImplementedError.superclass).to eq(SlackBot::Error)
    end

    it "SlackBot::Error inherits from StandardError" do
      expect(SlackBot::Error.superclass).to eq(StandardError)
    end
  end

  describe SlackBot::Errors::HandlerClassNotFound do
    it "has class_name and handler_classes attributes" do
      error = described_class.new("TestClass", handler_classes: {test: Class})
      expect(error.class_name).to eq("TestClass")
      expect(error.handler_classes).to eq({test: Class})
    end

    it "has a descriptive message" do
      error = described_class.new("TestClass", handler_classes: {})
      expect(error.message).to include("TestClass")
    end
  end

  describe SlackBot::Errors::InteractionClassNotImplemented do
    it "has class_name attribute" do
      error = described_class.new("TestClass")
      expect(error.class_name).to eq("TestClass")
    end
  end

  describe SlackBot::Errors::ViewClassNotImplemented do
    it "has class_name attribute" do
      error = described_class.new("TestClass")
      expect(error.class_name).to eq("TestClass")
    end
  end

  describe SlackBot::Errors::SlackResponseError do
    it "has error, data, and payload attributes" do
      error_data = {"ok" => false}
      payload_data = {view: {}}
      error = described_class.new("test_error", data: error_data, payload: payload_data)
      expect(error.error).to eq("test_error")
      expect(error.data).to eq(error_data)
      expect(error.payload).to eq(payload_data)
    end
  end

  describe SlackBot::Errors::UnknownActionTypeError do
    it "has action_type attribute" do
      error = described_class.new("block_actions")
      expect(error.action_type).to eq("block_actions")
    end

    it "has a descriptive message" do
      error = described_class.new("block_actions")
      expect(error.message).to include("block_actions")
    end
  end
end
