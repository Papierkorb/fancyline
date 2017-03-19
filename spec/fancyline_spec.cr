require "./spec_helper"

describe Fancyline do
  describe "#readline" do
    it "shows a prompt and returns upon accepting" do
      r, w = IO.pipe
      output = FakeTty.new
      fancy = Fancyline.new(r, output)

      spawn do
        w.puts "My Input\r"
        w.close
      end

      fancy.readline("> ").should eq "My Input"
      output.to_s.should match(/> My Input/)
    end

    it "rejects upon hitting Ctrl-D" do
      r, w = IO.pipe
      output = FakeTty.new
      fancy = Fancyline.new(r, output)

      spawn do
        w.puts "\u{4}"
        w.close
      end

      fancy.readline("> ").should be_nil
      output.to_s.should match(/> /)
    end

    it "raises an Interrupt upon hitting Ctrl-C" do
      r, w = IO.pipe
      output = FakeTty.new
      fancy = Fancyline.new(r, output)

      spawn do
        w.puts "My Input\u{3}"
        w.close
      end

      expect_raises(Fancyline::Interrupt) do
        fancy.readline("> ")
      end

      output.to_s.should match(/> My Input/)
    end
  end

  describe "#grab_output" do
    context "if a context exists" do
      r, w = IO.pipe
      output = FakeTty.new
      fancy = Fancyline.new(r, output)

      spawn do
        fancy.grab_output do
          output.puts "-Grabbed-"
        end

        w.puts "My Input\r"
        w.close
      end

      fancy.readline("> ").should eq "My Input"
      output.to_s.should match(/-Grabbed-.*> My Input/m)
    end

    context "if NO context exists" do
      it "yields" do
        fancy = Fancyline.new
        yielded = false

        fancy.grab_output do
          yielded = true
        end

        yielded.should be_true
      end
    end
  end
end
