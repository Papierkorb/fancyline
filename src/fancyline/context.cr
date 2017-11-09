class Fancyline
  # Context of a currently running prompt.  You usually don't have to
  # instantiate one yourself, but use `Fancyline` instead.
  #
  # `Context` implements most of the user-facing operations like handling user
  # input and rendering the resulting output.
  class Context

    # Status of a `Context` instance.
    enum Status
      Reading # We're reading user input
      Accepted # The input was accepted (Return key)
      Rejected # The input was rejected (Ctrl-D)
    end

    # The `Fancyline` instance this context was built from.
    getter fancyline : Fancyline

    # Status of this context.  Use `#accept!` and `#reject!` to modify it.
    getter status : Status = Status::Reading

    # Line editor used by the context
    getter editor : Editor

    # Currently active widget (if any)
    getter widget : Widget?

    def initialize(@fancyline, prompt : String)
      @sub_lines = 0
      @editor = Editor.new(@fancyline, prompt)

      # Set this later as we're referencing `self`.
      @editor.display_func = ->(line : String) do
        @fancyline.display.call self, line
      end
    end

    # Delegates to `Fancyline#tty`.
    def tty : Tty
      @fancyline.tty
    end

    # Starts *widget* in this context.  If there's already a widget active,
    # returns `false`.  Returns `true` otherwise and calls `Widget#start`.
    #
    # Usually called from a key handler (See `#actions`).
    #
    # If a widget decides to not start, it's safe to call `#stop_widget` from
    # inside `Widget#start` to directly remove the widget again.  This does not
    # affect the result of this method, which will stay to be `true`.
    def start_widget(widget : Widget) : Bool
      return false if @widget

      @widget = widget
      widget.start self
      true
    end

    # If a widget is currently running, stops and removes it.  If no widget is
    # running does nothing.
    def stop_widget
      widget = @widget
      return if widget.nil?

      widget.stop self
      @widget = nil
    end

    # Creates a new editor.  Can be used by widgets to show an editor.
    # The *prompt* has to start at the beginning of the output line.
    def create_editor(prompt : String, line = "", cursor = 0) : Editor
      Editor.new(@fancyline, prompt, line, cursor)
    end

    # Like `#create_editor`, but uses the supplied block as display function,
    # allowing the caller to transform an output string before writing it to
    # the screen.
    def create_editor(prompt : String, line = "", cursor = 0,
                      &block : Editor::DisplayFunc) : Editor
      Editor.new(@fancyline, prompt, line, cursor, block)
    end

    # Clears the sub-lines, moves the cursor onto the next line, and returns the
    # current line buffer if it was accepted.
    def destruct : String?
      clear_info
      @fancyline.output.print "\n\r"
      @editor.line if @status.accepted?
    end

    # Handles an input character, as if the user typed it.
    #
    # This method should not be called from a widget.  Call `#handle_control`
    # or `#put_char` directly instead.
    def handle(char : Char)
      if w = @widget
        return if w.handle(self, char)
      end

      if char.control?
        key = Key.read_control(char){ @fancyline.input.read_char }
        handle_control key if key
      else
        @editor.put_char char
      end
    end

    # Handles a control *key*, as if the user had input it.
    def handle_control(key : Key::Control)
      if handler = @fancyline.actions[key]?
        handler.call self
      end
    end

    # Accepts the current input.  This will make `Fancyline#readline` return
    # the line buffer in its current form to the caller.
    def accept!
      @status = Status::Accepted
    end

    # Rejects the input.  This will make `Fancyline#readline` return `nil` to
    # the caller.
    def reject!
      @status = Status::Rejected
    end

    # Draws the context onto the terminal.  This method is called by
    # `Fancyline#readline` after every key-press.
    def draw
      draw_info
      @editor.draw
    end

    # Clears the sub information lines.  The cursor position is retained.
    def clear_info
      @fancyline.tty.cursor_restore do
        @sub_lines.times do
          @fancyline.output.print "\n"
          @fancyline.tty.prepare_line
        end
      end
    end

    # Draws the sub information lines.  The cursor is assumed to be a line above
    # the target lines.  The cursor will be moved back to the line, but placed
    # at an unknown column.
    def draw_info
      sub_info = @fancyline.sub_info.call self

      # Clear all lines we ever needed.  If we once had more middlewares than
      # now, clear those lines anyway.
      @sub_lines = { sub_info.size, @sub_lines }.max

      sub_info.each do |line|
        @fancyline.output.print "\n"

        if line.is_a?(Drawable)
          line.draw(self)
        else # line is a String
          @fancyline.tty.prepare_line
          @fancyline.output.print line
        end
      end

      @fancyline.tty.move_cursor(0, -sub_info.size)
    end
  end
end
