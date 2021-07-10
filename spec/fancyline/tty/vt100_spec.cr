require "../../spec_helper"

private def tty
  io = IO::Memory.new
  tty = Fancyline::Tty::Vt100.new io
  yield tty
  io.to_s
end

describe Fancyline::Tty::Vt100 do
  describe "#prepare_line" do
    it "moves to the start and clears the line" do
      tty(&.prepare_line).should eq "\r\e[2K"
    end
  end

  describe "#clear_line" do
    it "clears the line" do
      tty(&.clear_line).should eq "\e[2K"
    end
  end

  describe "#cursor_to_start" do
    it "moves to the start" do
      tty(&.cursor_to_start).should eq "\r"
    end
  end

  describe "#move_cursor" do
    it "moves to the left" do
      tty(&.move_cursor(-5, 0)).should eq "\e[5D"
    end

    it "moves to the right" do
      tty(&.move_cursor(5, 0)).should eq "\e[5C"
    end

    it "moves up" do
      tty(&.move_cursor(0, -5)).should eq "\e[5A"
    end

    it "moves down" do
      tty(&.move_cursor(0, 5)).should eq "\e[5B"
    end

    it "moves in two directions at once" do
      tty(&.move_cursor(-3, 4)).should eq "\e[3D\e[4B"
    end
  end

  describe "#cursor_restore" do
    it "saves the cursor, yields, and then restores" do
      io = IO::Memory.new
      tty = Fancyline::Tty::Vt100.new io
      tty.cursor_restore do
        io.print "-Ok-"
      end

      io.to_s.should eq "\e[s-Ok-\e[u"
    end
  end

  describe "#clear_screen" do
    it "clears the screen and moves to the start" do
      tty(&.clear_screen).should eq "\e[2J\e[H"
    end
  end

  describe "#switch_to_alternate_screen" do
    it "switches to the alternate screen" do
      tty(&.switch_to_alternate_screen).should eq "\e[?1049h"
    end
  end

  describe "#switch_from_alternate_screen" do
    it "switches from the alternate screen" do
      tty(&.switch_from_alternate_screen).should eq "\e[?1049l"
    end
  end
end
