require "stringio"
require_relative "../usr/lib/release_version_check"

RSpec.describe ReleaseVersionCheck do
  describe ".release_confirmed?" do
    it "accepts an entered confirmation" do
      expect(described_class.release_confirmed?(StringIO.new("Y\n"))).to be(true)
      expect(described_class.release_confirmed?(StringIO.new("\n"))).to be(true)
    end

    it "rejects an explicit refusal and end of input" do
      expect(described_class.release_confirmed?(StringIO.new("n\n"))).to be(false)
      expect(described_class.release_confirmed?(StringIO.new(""))).to be(false)
    end
  end
end
