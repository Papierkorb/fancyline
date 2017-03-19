require "../spec_helper"

private def sequence(key : Int32, *seq)
  idx = -1

  Fancyline::Key.read_control(key.unsafe_chr) do
    idx += 1
    seq[idx]?.try(&.unsafe_chr)
  end
end

describe Fancyline::Key do
  describe ".read_control" do
    it "detects Ctrl-Letter keys" do
      sequence(1).should eq(Fancyline::Key::Control::CtrlA)
      sequence(2).should eq(Fancyline::Key::Control::CtrlB)
      sequence(3).should eq(Fancyline::Key::Control::CtrlC)
      sequence(4).should eq(Fancyline::Key::Control::CtrlD)
      sequence(5).should eq(Fancyline::Key::Control::CtrlE)
      sequence(6).should eq(Fancyline::Key::Control::CtrlF)
      sequence(7).should eq(Fancyline::Key::Control::CtrlG)
      sequence(8).should eq(Fancyline::Key::Control::CtrlH)
      sequence(9).should eq(Fancyline::Key::Control::Tab) # == ^I
      sequence(10).should eq(Fancyline::Key::Control::CtrlJ)
      sequence(11).should eq(Fancyline::Key::Control::CtrlK)
      sequence(12).should eq(Fancyline::Key::Control::CtrlL)
      sequence(13).should eq(Fancyline::Key::Control::Return) # == ^M
      sequence(14).should eq(Fancyline::Key::Control::CtrlN)
      sequence(15).should eq(Fancyline::Key::Control::CtrlO)
      sequence(16).should eq(Fancyline::Key::Control::CtrlP)
      sequence(17).should eq(Fancyline::Key::Control::CtrlQ)
      sequence(18).should eq(Fancyline::Key::Control::CtrlR)
      sequence(19).should eq(Fancyline::Key::Control::CtrlS)
      sequence(20).should eq(Fancyline::Key::Control::CtrlT)
      sequence(21).should eq(Fancyline::Key::Control::CtrlU)
      sequence(22).should eq(Fancyline::Key::Control::CtrlV)
      sequence(23).should eq(Fancyline::Key::Control::CtrlW)
      sequence(24).should eq(Fancyline::Key::Control::CtrlX)
      sequence(25).should eq(Fancyline::Key::Control::CtrlY)
      sequence(26).should eq(Fancyline::Key::Control::CtrlZ)
    end

    it "detects backspace" do
      sequence(127).should eq(Fancyline::Key::Control::Backspace)
    end
  end

  describe "escape sequences" do
    it "detects Alt-Letter keys" do
      sequence(27, 97).should eq(Fancyline::Key::Control::AltA)
      sequence(27, 98).should eq(Fancyline::Key::Control::AltB)
      sequence(27, 99).should eq(Fancyline::Key::Control::AltC)
      sequence(27, 100).should eq(Fancyline::Key::Control::AltD)
      sequence(27, 101).should eq(Fancyline::Key::Control::AltE)
      sequence(27, 102).should eq(Fancyline::Key::Control::AltF)
      sequence(27, 103).should eq(Fancyline::Key::Control::AltG)
      sequence(27, 104).should eq(Fancyline::Key::Control::AltH)
      sequence(27, 105).should eq(Fancyline::Key::Control::AltI)
      sequence(27, 106).should eq(Fancyline::Key::Control::AltJ)
      sequence(27, 107).should eq(Fancyline::Key::Control::AltK)
      sequence(27, 108).should eq(Fancyline::Key::Control::AltL)
      sequence(27, 109).should eq(Fancyline::Key::Control::AltM)
      sequence(27, 110).should eq(Fancyline::Key::Control::AltN)
      sequence(27, 111).should eq(Fancyline::Key::Control::AltO)
      sequence(27, 112).should eq(Fancyline::Key::Control::AltP)
      sequence(27, 113).should eq(Fancyline::Key::Control::AltQ)
      sequence(27, 114).should eq(Fancyline::Key::Control::AltR)
      sequence(27, 115).should eq(Fancyline::Key::Control::AltS)
      sequence(27, 116).should eq(Fancyline::Key::Control::AltT)
      sequence(27, 117).should eq(Fancyline::Key::Control::AltU)
      sequence(27, 118).should eq(Fancyline::Key::Control::AltV)
      sequence(27, 119).should eq(Fancyline::Key::Control::AltW)
      sequence(27, 120).should eq(Fancyline::Key::Control::AltX)
      sequence(27, 121).should eq(Fancyline::Key::Control::AltY)
      sequence(27, 122).should eq(Fancyline::Key::Control::AltZ)
    end

    it "detects arrow keys" do
      sequence(27, 91, 65).should eq(Fancyline::Key::Control::Up)
      sequence(27, 91, 66).should eq(Fancyline::Key::Control::Down)
      sequence(27, 91, 67).should eq(Fancyline::Key::Control::Right)
      sequence(27, 91, 68).should eq(Fancyline::Key::Control::Left)
    end

    it "detects Ctrl+arrow keys" do
      sequence(27, 91, 49, 59, 53, 65).should eq(Fancyline::Key::Control::CtrlUp)
      sequence(27, 91, 49, 59, 53, 66).should eq(Fancyline::Key::Control::CtrlDown)
      sequence(27, 91, 49, 59, 53, 67).should eq(Fancyline::Key::Control::CtrlRight)
      sequence(27, 91, 49, 59, 53, 68).should eq(Fancyline::Key::Control::CtrlLeft)
    end

    it "detects Shift+arrow keys" do
      sequence(27, 91, 49, 59, 50, 65).should eq(Fancyline::Key::Control::ShiftUp)
      sequence(27, 91, 49, 59, 50, 66).should eq(Fancyline::Key::Control::ShiftDown)
      sequence(27, 91, 49, 59, 50, 67).should eq(Fancyline::Key::Control::ShiftRight)
      sequence(27, 91, 49, 59, 50, 68).should eq(Fancyline::Key::Control::ShiftLeft)
    end

    it "detects Alt+arrow keys" do
      sequence(27, 91, 49, 59, 51, 65).should eq(Fancyline::Key::Control::AltUp)
      sequence(27, 91, 49, 59, 51, 66).should eq(Fancyline::Key::Control::AltDown)
      sequence(27, 91, 49, 59, 51, 67).should eq(Fancyline::Key::Control::AltRight)
      sequence(27, 91, 49, 59, 51, 68).should eq(Fancyline::Key::Control::AltLeft)
    end

    it "detects home keys" do
      sequence(27, 91, 72).should eq(Fancyline::Key::Control::Home)
      sequence(27, 91, 70).should eq(Fancyline::Key::Control::End)
      sequence(27, 91, 53, 126).should eq(Fancyline::Key::Control::PageUp)
      sequence(27, 91, 54, 126).should eq(Fancyline::Key::Control::PageDown)
      sequence(27, 91, 50, 126).should eq(Fancyline::Key::Control::Insert)
      sequence(27, 91, 51, 126).should eq(Fancyline::Key::Control::Delete)
    end

    it "detects F-keys" do
      sequence(27, 79, 80).should eq(Fancyline::Key::Control::F1)
      sequence(27, 79, 81).should eq(Fancyline::Key::Control::F2)
      sequence(27, 79, 82).should eq(Fancyline::Key::Control::F3)
      sequence(27, 79, 83).should eq(Fancyline::Key::Control::F4)

      sequence(27, 91, 49, 53, 126).should eq(Fancyline::Key::Control::F5)
      sequence(27, 91, 49, 55, 126).should eq(Fancyline::Key::Control::F6)
      sequence(27, 91, 49, 56, 126).should eq(Fancyline::Key::Control::F7)
      sequence(27, 91, 49, 57, 126).should eq(Fancyline::Key::Control::F8)

      sequence(27, 91, 50, 48, 126).should eq(Fancyline::Key::Control::F9)
      sequence(27, 91, 50, 49, 126).should eq(Fancyline::Key::Control::F10)
      sequence(27, 91, 50, 51, 126).should eq(Fancyline::Key::Control::F11)
      sequence(27, 91, 50, 52, 126).should eq(Fancyline::Key::Control::F12)
    end
  end
end
