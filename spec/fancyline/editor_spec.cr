require "../spec_helper"

private def editor
  tty = Fancyline::Tty::Dumb.new
  fancy = Fancyline.new(tty: tty)
  Fancyline::Editor.new(fancy, "$ ")
end

describe Fancyline::Editor do
  describe "#empty?" do
    context "if the line buffer is empty" do
      it "returns true" do
        editor.empty?.should be_true
      end
    end

    context "if the line buffer is NOT empty" do
      it "returns false" do
        edit = editor
        edit.line = "foo"
        edit.empty?.should be_false
      end
    end
  end

  describe "#clear" do
    it "clears the buffer and resets the cursor" do
      edit = editor
      edit.line = "foo"
      edit.cursor = 4

      edit.clear

      edit.empty?.should be_true
      edit.line.should eq ""
      edit.cursor.should eq 0
    end
  end

  describe "#move_cursor" do
    it "moves the cursor by an offset" do
      edit = editor
      edit.line = "foobarbaz"
      edit.cursor = 5

      edit.move_cursor 2
      edit.cursor.should eq 7

      edit.move_cursor -3
      edit.cursor.should eq 4
    end

    context "if moving to less-than zero" do
      it "clamps to 0" do
        edit = editor
        edit.cursor = 4

        edit.move_cursor Int32::MIN
        edit.cursor.should eq 0
      end
    end

    context "if moving to greater-than buffer length" do
      it "clamps to buffer-line size" do
        edit = editor
        edit.line = "foo"
        edit.cursor = 2

        edit.move_cursor Int32::MAX
        edit.cursor.should eq 3
      end
    end
  end

  describe "#apply" do
    it "runs the completion and adjusts the cursor" do
      edit = editor
      edit.line = "foobarbaz"
      edit.cursor = 8

      edit.apply Fancyline::Completion.new(1..2, "OO")

      edit.line.should eq "fOObarbaz"
      edit.cursor.should eq 3
    end
  end

  describe "#word_at_offset" do
    context "if a word is around the offset" do
      it "finds the word the offset starts at" do
        edit = editor
        edit.line = "foo bar baz"

        edit.word_at_offset(5).should eq({ "bar", 4 })
      end

      it "finds the word the offset is in" do
        edit = editor
        edit.line = "foo bar baz"

        edit.word_at_offset(6).should eq({ "bar", 4 })
      end

      it "finds the word the offset is just after" do
        edit = editor
        edit.line = "foo bar baz"

        edit.word_at_offset(7).should eq({ "bar", 4 })
      end

      it "finds the word at the end" do
        edit = editor
        edit.line = "foo bar baz"

        edit.word_at_offset(edit.line.size).should eq({ "baz", 8 })
      end
    end

    context "if no word is around the offset" do
      it "returns nil" do
        edit = editor
        edit.line = "foo     bar baz"

        edit.word_at_offset(5).should be_nil
      end
    end
  end

  describe "#put_char" do
    it "puts the character at the cursor position and advances the cursor" do
      edit = editor
      edit.line = "foo bar baz"
      edit.cursor = 4

      edit.put_char 'Ä'
      edit.line.should eq "foo Äbar baz"
      edit.cursor.should eq 5
    end
  end

  describe "#remove_at_cursor" do
    it "removes to the left" do
      edit = editor
      edit.line = "foo bar"
      edit.cursor = 4

      edit.remove_at_cursor -3

      edit.line.should eq "fbar"
      edit.cursor.should eq 1
    end

    it "removes to the left" do
      edit = editor
      edit.line = "foo bar"
      edit.cursor = 3

      edit.remove_at_cursor 3

      edit.line.should eq "foor"
      edit.cursor.should eq 3
    end

    context "out of bounds cases" do
      it "clamps positive" do
        edit = editor
        edit.line = "foo bar"
        edit.cursor = 3

        edit.remove_at_cursor Int32::MAX

        edit.line.should eq "foo"
        edit.cursor.should eq 3
      end

      it "clamps negative" do
        edit = editor
        edit.line = "foo bar"
        edit.cursor = 4

        edit.remove_at_cursor Int32::MIN

        edit.line.should eq "bar"
        edit.cursor.should eq 0
      end
    end
  end
end
