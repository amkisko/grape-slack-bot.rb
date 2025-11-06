require "spec_helper"

describe SlackBot::Concerns::InteractionKlass do
  let(:test_class) do
    Class.new do
      include SlackBot::Concerns::InteractionKlass
    end
  end

  describe ".included" do
    it "extends the base class with ClassMethods" do
      expect(test_class).to respond_to(:interaction_klass)
      expect(test_class).to respond_to(:interaction)
    end
  end

  describe ".interaction_klass" do
    it "raises InteractionClassNotImplemented when not set" do
      expect { test_class.interaction_klass }.to raise_error(SlackBot::Errors::InteractionClassNotImplemented) do |error|
        expect(error.class_name).to eq(test_class.name)
      end
    end

    context "when interaction is set" do
      let(:interaction_class) { Class.new }

      before do
        test_class.interaction(interaction_class)
      end

      it "returns the interaction class" do
        expect(test_class.interaction_klass).to eq(interaction_class)
      end
    end
  end

  describe ".interaction" do
    it "defines interaction_klass method" do
      interaction_class = Class.new
      test_class.interaction(interaction_class)
      expect(test_class.interaction_klass).to eq(interaction_class)
    end
  end
end
