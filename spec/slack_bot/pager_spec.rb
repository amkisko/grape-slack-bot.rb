require "spec_helper"

describe SlackBot::Pager do
  let(:args) do
    instance_double(SlackBot::Args)
  end
  before do
    allow(args).to receive(:[]).with(:page).and_return(1)
    allow(args).to receive(:[]).with(:per_page).and_return(10)
  end

  describe "#total_count" do
    it "returns the count of the source cursor" do
      source_cursor = double(count: 10)
      pager = described_class.new(source_cursor, args: args)
      expect(pager.total_count).to eq(10)
    end
  end

  describe "#pages_count" do
    it "returns the count of the source cursor divided by the limit" do
      source_cursor = double(count: 10)
      pager = described_class.new(source_cursor, args: args, limit: 5)
      expect(pager.pages_count).to eq(2)
    end

    it "returns the count of the source cursor divided by the limit" do
      source_cursor = double(count: 11)
      pager = described_class.new(source_cursor, args: args, limit: 5)
      expect(pager.pages_count).to eq(3)
    end
  end

  describe "#offset" do
    it "returns the offset based on the page and limit" do
      source_cursor = double(count: 10)
      pager = described_class.new(source_cursor, args: args, limit: 5, page: 2)
      expect(pager.offset).to eq(5)
    end
  end

  describe "#cursor" do
    it "returns the cursor with the limit and offset" do
      source_cursor = double(count: 10)
      expect(source_cursor).to receive(:limit).with(5).and_return(source_cursor)
      expect(source_cursor).to receive(:offset).with(5).and_return(source_cursor)
      pager = described_class.new(source_cursor, args: args, limit: 5, page: 2)
      expect(pager.cursor).to eq(source_cursor)
    end
  end

  describe "#initialize" do
    it "uses DEFAULT_LIMIT when limit is not provided" do
      source_cursor = double(count: 10)
      pager = described_class.new(source_cursor, args: args)
      expect(pager.limit).to eq(SlackBot::Pager::DEFAULT_LIMIT)
    end

    it "uses DEFAULT_PAGE when page is not provided" do
      source_cursor = double(count: 10)
      pager = described_class.new(source_cursor, args: args)
      expect(pager.page).to eq(SlackBot::Pager::DEFAULT_PAGE)
    end

    it "uses limit from args when provided" do
      source_cursor = double(count: 10)
      allow(args).to receive(:[]).with(:per_page).and_return(20)
      pager = described_class.new(source_cursor, args: args)
      expect(pager.limit).to eq(20)
    end

    it "uses page from args when provided" do
      source_cursor = double(count: 10)
      allow(args).to receive(:[]).with(:page).and_return(3)
      pager = described_class.new(source_cursor, args: args)
      expect(pager.page).to eq(3)
    end

    it "prioritizes explicit limit over args" do
      source_cursor = double(count: 10)
      allow(args).to receive(:[]).with(:per_page).and_return(20)
      pager = described_class.new(source_cursor, args: args, limit: 15)
      expect(pager.limit).to eq(15)
    end

    it "prioritizes explicit page over args" do
      source_cursor = double(count: 10)
      allow(args).to receive(:[]).with(:page).and_return(3)
      pager = described_class.new(source_cursor, args: args, page: 2)
      expect(pager.page).to eq(2)
    end
  end
end
