require "../spec_helper"

private def ctx(*args)
  fancy = Fancyline.new(*args)
  Fancyline::Context.new fancy, "$ "
end

private class TestWidget < Fancyline::Widget
  getter context : Fancyline::Context?
  getter started = false
  getter stopped = false
  getter char : Char?

  def start(ctx)
    @context = ctx
    @started = true
  end

  def stop(ctx)
    @context = ctx
    @stopped = true
  end

  def handle(ctx, char) : Bool
    @context = ctx
    @char = char
    char == 'A' || char == 127.unsafe_chr
  end
end

describe Fancyline::Context do
  describe "#start_widget" do
    context "if no widget is active" do
      it "sets it as active and starts it" do
        widget = TestWidget.new
        c = ctx
        c.start_widget(widget).should be_true

        c.widget.should be widget
        widget.context.should be c
        widget.started.should be_true
      end
    end

    context "if a widget is active" do
      it "rejects the new widget" do
        widget1 = TestWidget.new
        widget2 = TestWidget.new
        c = ctx
        c.start_widget(widget1).should be_true
        c.start_widget(widget2).should be_false

        c.widget.should be widget1
        widget2.started.should be_false
      end
    end
  end

  describe "#stop_widget" do
    context "if a widget is active" do
      it "stops and removes it" do
        widget = TestWidget.new
        c = ctx
        c.start_widget(widget).should be_true
        widget.stopped.should be_false

        c.stop_widget
        c.widget.should be_nil
        widget.stopped.should be_true
      end
    end

    context "if no widget is active" do
      it "does nothing" do
        ctx.stop_widget # Doesn't raise, either
      end
    end
  end

  describe "#destruct" do
    context "if the status is Running" do
      it "clears the sub-info and returns nil" do
        io = IO::Memory.new
        c = ctx(io, io)
        c.editor.line = "foobar"

        c.destruct.should be_nil
        io.to_s.should eq "\n\r"
      end
    end

    context "if the status is Accepted" do
      it "clears the sub-info and returns the line buffer" do
        io = IO::Memory.new
        c = ctx(io, io)
        c.editor.line = "foobar"

        c.accept!
        c.destruct.should eq "foobar"
        io.to_s.should eq "\n\r"
      end
    end

    context "if the status is Rejected" do
      it "clears the sub-info and returns the line buffer" do
        io = IO::Memory.new
        c = ctx(io, io)
        c.editor.line = "foobar"

        c.reject!
        c.destruct.should be_nil
        io.to_s.should eq "\n\r"
      end
    end
  end

  describe "#handle" do
    context "if a widget is active" do
      context "and the Widget#handle returns true" do
        it "stops processing" do
          widget = TestWidget.new
          c = ctx.tap(&.start_widget(widget))

          c.editor.line = "foobar"
          c.handle 'A'

          c.editor.line.should eq "foobar"
          widget.context.should be c
          widget.char.should eq 'A'
        end
      end

      context "and the Widget#handle returns false" do
        it "stops processing" do
          widget = TestWidget.new
          c = ctx.tap(&.start_widget(widget))

          c.editor.line = "foobar"
          c.handle 'B'

          c.editor.line.should eq "Bfoobar"
          widget.context.should be c
          widget.char.should eq 'B'
        end
      end
    end

    context "if it's a control input" do
      it "calls the widget first if any" do
        widget = TestWidget.new
        c = ctx.tap(&.start_widget(widget))

        caught_ctx = nil
        c.fancyline.actions.set(Fancyline::Key::Control::Backspace) do |ctx|
          caught_ctx = ctx
        end

        c.editor.line = "foobar"
        c.handle 127.unsafe_chr

        caught_ctx.should be_nil
        c.editor.line.should eq "foobar"
        widget.context.should be c
        widget.char.should eq 127.unsafe_chr
      end

      it "calls the key binding for it" do
        c = ctx
        caught_ctx = nil

        c.fancyline.actions.set(Fancyline::Key::Control::Backspace) do |ctx|
          caught_ctx = ctx
        end

        c.handle 127.unsafe_chr
        caught_ctx.should be c
      end
    end

    context "if it's a printable input" do
      it "passes it on to the editor" do
        c = ctx
        c.editor.line = "foobar"

        c.handle 'A'

        c.editor.line.should eq "Afoobar"
      end
    end
  end

  describe "#draw" do
    it "draws the prompt" do
      io = IO::Memory.new # Dumb TTY
      c = ctx(io, io)
      c.editor.line = "foo"

      c.draw

      io.to_s.should eq "$ foo"
    end

    it "uses the display middleware" do
      io = FakeTty.new
      c = ctx(io, io)

      caught_ctx = nil
      caught_line = nil

      c.editor.line = "Foo"
      c.fancyline.display.add do |ctx, line, y|
        caught_ctx = ctx
        caught_line = line
        y.call(ctx, ">#{line}<") # Don't do this in non-test code :)
      end

      c.draw

      caught_ctx.should be c
      caught_line.should be c.editor.line
      io.to_s.includes?("$ >Foo<").should be_true
    end

    it "uses the sub_info middleware" do
      io = FakeTty.new
      c = ctx(io, io)

      caught_ctx = nil
      caught_line = nil

      c.editor.line = "Foo"
      c.fancyline.sub_info.add do |ctx, y|
        caught_ctx = ctx
        y.call(ctx) << "Okay"
      end

      c.draw

      # Make sure the sub_info is rendered first, THEN the prompt.
      io.to_s.should match(/Okay.*\$ Foo/i)
      caught_ctx.should be c
    end
  end
end
