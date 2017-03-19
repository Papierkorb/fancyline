require "../spec_helper"

describe Fancyline::Tty do
  describe ".build" do
    context "if IO#tty? is true" do
      it "returns a Vt100 instance" do
        Fancyline::Tty.build(FakeTty.new).should be_a Fancyline::Tty::Vt100
      end
    end

    context "if IO#tty? is false" do
      it "returns a Dumb instance" do
        Fancyline::Tty.build(IO::Memory.new).should be_a Fancyline::Tty::Dumb
      end
    end
  end
end
