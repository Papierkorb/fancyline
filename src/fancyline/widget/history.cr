class Fancyline
  class Widget
    # Implements a simple history access feature.  Activated by hitting the "Up"
    # key, then accepts "Up" and "Down" to navigate the history.
    #
    # The source code of this widget has exhaustive commentary, which hopefully
    # makes this useful to you, the reader, for studying!  It's put to use in
    # `KeyAction::DEFAULT`s handler for `Key::Control::Up`.
    class History < Widget

      # The history we're operating on.  Initialized in `#start`.
      getter! history : Fancyline::History?

      @original_line = ""
      @original_cursor = 0
      @position = 0

      # Starts the widget.
      def start(ctx : Context)
        # Save the original line
        @original_line = ctx.editor.line
        @original_cursor = ctx.editor.cursor
        @history = ctx.fancyline.history

        # Show the most-recent entry from the history initially.
        show_entry ctx, -1
      end

      # We don't need a `#stop` for this widget.  It looks like this:
      # def stop(ctx : Contex)
      #   puts "Stopping"
      # end

      # Handles user input.  Called by `Fancyline::Context#handle`.
      def handle(ctx : Context, char : Char) : Bool
        # If not a control character, stop the widget and resume normal
        # operation in `Context`.  The default implementation of `#handle` does
        # exactly what we need.
        return super unless char.control?

        # Turn the `char` into a full blown `Key::Control`.  May read additional
        # data from the input.
        key = Key.read_control(char){ ctx.fancyline.input.read_char }
        case key
        when Key::Control::Up
          show_entry ctx, -1
        when Key::Control::Down
          show_entry ctx, +1
        else # If the key is unexpected, stop the widget.
          ctx.stop_widget

          # ASCII key sequences are mostly made of many key strokes sent to the
          # program.  Simply returning `false` wouldn't work, as we already read
          # any extra key strokes from the input.  Otherwise we'd confuse they
          # key sequence parser, which will most likely result in weird
          # behaviour for the user.
          ctx.handle_control(key) if key
        end

        true # Yes, we took care of the input
      end

      # Shows a history entry, moving in it by *offset* entries.
      def show_entry(ctx, offset)
        # We're counting backwards through the history. `-1` being most recent.
        @position = (@position + offset).clamp(-history.lines.size, 0)

        # Position 0 is special: It's the original user input.
        if @position == 0
          ctx.editor.line = @original_line
          ctx.editor.cursor = @original_cursor
        else
          ctx.editor.line = history.lines[@position]
          ctx.editor.cursor = ctx.editor.line.size
        end
      end
    end
  end
end
