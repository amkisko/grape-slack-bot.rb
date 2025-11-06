require "spec_helper"

describe SlackBot::Concerns::ViewKlass do
  let(:test_class) do
    Class.new do
      include SlackBot::Concerns::ViewKlass
    end
  end

  describe ".included" do
    it "extends the base class with ClassMethods" do
      expect(test_class).to respond_to(:view_klass)
      expect(test_class).to respond_to(:view)
    end
  end

  describe ".view_klass" do
    it "raises ViewClassNotImplemented when not set" do
      expect { test_class.view_klass }.to raise_error(SlackBot::Errors::ViewClassNotImplemented) do |error|
        expect(error.class_name).to eq(test_class.name)
      end
    end

    context "when view is set" do
      let(:view_class) { Class.new }

      before do
        test_class.view(view_class)
      end

      it "returns the view class" do
        expect(test_class.view_klass).to eq(view_class)
      end
    end
  end

  describe ".view" do
    it "defines view_klass method" do
      view_class = Class.new
      test_class.view(view_class)
      expect(test_class.view_klass).to eq(view_class)
    end
  end
end
