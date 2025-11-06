require "spec_helper"

describe SlackBot::Concerns::PagerKlass do
  let(:test_class) do
    Class.new do
      include SlackBot::Concerns::PagerKlass
    end
  end

  describe ".included" do
    it "extends the base class with ClassMethods" do
      expect(test_class).to respond_to(:pager_klass)
      expect(test_class).to respond_to(:pager)
    end
  end

  describe ".pager_klass" do
    it "returns SlackBot::Pager by default" do
      expect(test_class.pager_klass).to eq(SlackBot::Pager)
    end

    context "when pager is set" do
      let(:custom_pager_class) { Class.new }

      before do
        test_class.pager(custom_pager_class)
      end

      it "returns the custom pager class" do
        expect(test_class.pager_klass).to eq(custom_pager_class)
      end
    end
  end

  describe ".pager" do
    it "defines pager_klass method" do
      custom_pager_class = Class.new
      test_class.pager(custom_pager_class)
      expect(test_class.pager_klass).to eq(custom_pager_class)
    end
  end
end
