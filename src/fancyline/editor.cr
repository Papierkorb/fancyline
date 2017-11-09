class Fancyline
  # Editor for a line of input featuring a prompt.  Used by `Context` for the
  # main prompt, but can also used by Widgets to show an editor e.g. in a
  # sub_info middleware.
  #
  # Use `Context#create_editor` instead of instantiating this yourself.
  class Editor
    include Drawable

    # Function used to transform a line to a displayable string
    alias DisplayFunc = Proc(String, String)

    # Default display function
    NOOP_DISPLAY_FUNC = ->(x : String){ x }

    # Minimum space (in characters) between the rprompt and the prompt line.
    # The right-prompt will be hidden if not satisfiable.
    RPROMPT_MARGIN = 1

    # The `Fancyline` instance this editor was built for.
    getter fancyline : Fancyline

    # Prompt, a string shown just before the user input.  Used to display
    # relevant, but usually short, information.
    property prompt : String

    # Prompt displayed on the right side, which will disappear when the prompt
    # input gets near it.  Can be used to display information like current time,
    # or other short data.  Popularized by ZSH.
    #
    # See `Fancyline#readline` to easily set this property.
    property rprompt : String?

    # Current line buffer.  Modifying it from everywhere outside the  `Context`
    # itself is fine and is done everywhere it's useful.  Make sure to also
    # update the `#cursor`.
    property line : String

    # Position of the cursor, starting right after the prompt.  Legal values are
    # `[0..line.size]` - Including `line.size`, just after the line buffer ends.
    property cursor : Int32 = 0

    # Function used to transform a line to a displayable string.
    property display_func : DisplayFunc

    def initialize(@fancyline, @tty : Tty, @prompt, @line = "", @cursor = 0,
                   @display_func = NOOP_DISPLAY_FUNC)
    end

    # Returns `true` if the line buffer is empty.
    def empty? : Bool
      @line.empty?
    end

    # Clears the line buffer and resets the cursor to its start position.
    def clear
      @line = ""
      @cursor = 0
    end

    # Moves the cursor in *offset* direction
    def move_cursor(offset : Int32)
      new_pos = @cursor.to_i64 + offset.to_i64 # Overflow prevention
      @cursor = new_pos.clamp(0, @line.size).to_i32
    end

    # Applies *completion* to the string buffer, and adjusts the cursor to be
    # just after the `Completion#word`.
    def apply(completion : Completion)
      @line = @line.sub(completion.range, completion.word)
      new_end = completion.range.begin + completion.word.size
      @cursor = new_end.clamp(0, @line.size)
    end

    # Looks for a word under, or just before, *offset*.
    # If found, returns a tuple of the word itself, and its starting position in
    # the current line buffer.  If not found, returns `nil`.
    #
    # A non-alphanumeric beginning is never considered to be a word.
    def word_at_offset(offset = @cursor) : Tuple(String, Int32)?
      return nil if @line.empty?
      words = @line.split(/\b/)

      pos = 0 # Find word under the offset
      word_idx = words.index do |w|
        pos += w.size
        offset < pos
      end

      # The offset is often just after the last word
      word_idx = words.size - 1 if word_idx.nil?
      if r = check_if_alphanumeric(words, word_idx, pos)
        return r
      end

      # If the current word is not alphanumeric, and the offset is pointing at
      # its start, try the previous word.

      pos -= words[word_idx].size
      return nil if pos != offset

      word_idx -= 1
      check_if_alphanumeric words, word_idx, pos
    end

    private def check_if_alphanumeric(words, word_idx, pos)
      return nil if word_idx < 0
      word = words[word_idx]
      pos -= word.size

      { word, pos } if word.[0]?.try(&.alphanumeric?)
    end

    # Writes *char* at the cursor, moving the cursor onward, as if the user had
    # input it.
    def put_char(char : Char)
      @line = @line.sub(@cursor...@cursor, char)
      @cursor += 1
    end

    # Removes *count* characters at the cursor position.  If *count* is
    # negative, moves the cursor *count* times to the left, removing *count*
    # characters (Backspace functionality).  If *count* is positive, removes
    # the following *count* characters, but doesn't move the cursor (Delete
    # functionality).
    # The *count* is automatically clamped to the line size, it can't get out of
    # bounds.
    def remove_at_cursor(count : Int32)
      if @cursor.to_i64 + count.to_i64 < 0
        count = -@cursor
      elsif @cursor.to_i64 + count.to_i64 > @line.size
        count = @line.size - @cursor
      end

      line = @line
      if count < 0
        leading = line[0...(@cursor + count)]
        trailing = (@cursor < line.size) ? line[@cursor..-1] : ""
      else
        leading = line[0...@cursor]
        trailing = line[(@cursor + count)..-1]
      end

      @line = leading + trailing
      @cursor += count if count < 0
    end

    # `Drawable` compatibility
    def draw(ctx : Context)
      draw
    end

    # Draws the context onto the terminal.  This method is called by
    # `Fancyline#readline` after every key-press.
    def draw
      # Fix cursor if someone forgot to fix its position.
      @cursor.clamp(0, @line.size)
      draw_prompt
    end

    # Draws the prompt and line buffer.
    def draw_prompt
      @tty.prepare_line
      @fancyline.output.print @prompt
      @fancyline.output.print @display_func.call(@line)

      prompt_dim = StringUtil.terminal_size @prompt
      draw_rprompt(prompt_dim)

      @tty.cursor_to_start
      @tty.move_cursor(prompt_dim.columns + @cursor, 0)
    end

    private def draw_rprompt(prompt_dim)
      rprompt = @rprompt
      return if rprompt.nil?

      rprompt_dim = StringUtil.terminal_size @rprompt
      return unless display_rprompt?(prompt_dim, rprompt_dim)

      @tty.cursor_to_start
      @tty.move_cursor(@tty.columns - rprompt_dim.columns, 0)
      @fancyline.output.print rprompt
    end

    # Returns `true` if the right-prompt can be displayed.
    private def display_rprompt?(prompt_dim, rprompt_dim)
      line_dim = StringUtil.terminal_size @line

      columns = line_dim.columns + prompt_dim.columns + rprompt_dim.columns
      @tty.columns - columns > RPROMPT_MARGIN
    end

    # Removes the prompt from the terminal.
    def clear_prompt
      @tty.prepare_line
    end
  end
end
