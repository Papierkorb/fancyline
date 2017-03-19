require "../spec_helper"

private def build(max = 5)
  history = Fancyline::History.new(max)
  history.ignore_prefix = "!"
  history
end

describe Fancyline::History do
  describe "#ignore?" do
    it "returns true for nil" do
      build.ignore?(nil).should be_true
    end

    it "returns true for empty string" do
      build.ignore?("").should be_true
    end

    it "returns true for blank string" do
      build.ignore?("  ").should be_true
    end

    it "returns true for string beginning with ignore prefix" do
      build.ignore?("!Ignore me").should be_true
    end

    it "returns true for string equal to most-recent history entry" do
      h = build
      h.lines.replace [ "foo" ]
      h.ignore?("foo").should be_true
    end

    it "returns false for any other" do
      build.ignore?("foo").should be_false
    end
  end

  describe "#add" do
    it "returns true for normal input" do
      h = build
      h.lines.empty?.should be_true
      h.add("foo").should be_true
      h.lines.should eq([ "foo" ])
    end

    it "returns false for ignored input" do
      h = build
      h.lines.empty?.should be_true
      h.add("!Ignore").should be_false
      h.lines.empty?.should be_true
    end

    it "appends new entries" do
      h = build
      h.lines.empty?.should be_true
      h.add("foo").should be_true
      h.add("bar").should be_true
      h.lines.should eq([ "foo", "bar" ])
    end

    it "removes old entries" do
      h = build
      h.lines.replace [ "1", "2", "3", "4", "5" ]
      h.add("foo").should be_true
      h.lines.should eq([ "2", "3", "4", "5", "foo" ])
    end
  end

  describe "#load" do
    it "replaces the existing history with the read one" do
      h = build
      h.load IO::Memory.new("1\n2\n3\n")
      h.lines.should eq([ "1", "2", "3" ])
    end

    it "skips blank lines" do
      h = build
      h.lines << "foo"
      h.load IO::Memory.new("1\n2\n  \n3\n")
      h.lines.should eq([ "1", "2", "3" ])
    end

    it "only retains the most recent lines until the maximum" do
      h = build
      h.load IO::Memory.new("1\n2\n3\n4\n5\n6")
      h.lines.should eq([ "2", "3", "4", "5", "6" ])
    end
  end

  describe "#save" do
    it "writes the history into the IO" do
      io = IO::Memory.new
      h = build
      h.lines << "foo" << "bar" << "baz"
      h.save io

      io.to_s.should eq "foo\nbar\nbaz\n"
    end
  end
end
