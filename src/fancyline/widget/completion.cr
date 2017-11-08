class Fancyline
  class Widget
    # Implements the user-interaction for TAB-autocompletion.  Completion
    # suggestions are created using the `Fancyline#autocomplete` middleware.
    class Completion < Widget
      # Hard limit of completions.  More are discarded.
      MAX_COMPLETIONS = 20

      @original_line = ""
      @original_cursor = 0
      @position = 0
      @quick_select = { } of Char => Fancyline::Completion
      @suggestions = [ ] of Fancyline::Completion

      @sub_info_handle = Cute::ConnectionHandle.new(0)

      def start(ctx : Context)
        # Save the original line
        @original_line = ctx.editor.line
        @original_cursor = ctx.editor.cursor

        # Try to find a word at the cursor
        range = ctx.editor.cursor...ctx.editor.cursor
        word = ""
        if found_word = ctx.editor.word_at_offset
          word = found_word[0]
          range = found_word[1]...(found_word[1] + word.size)
        end

        # Get suggestions
        fetch_suggestions(ctx, range, word)

        # If no suggestions are found do nothing.
        if @suggestions.empty?
          ctx.stop_widget
          return
        end

        # Only show the sub_info if we have more than one suggestion
        if @suggestions.size > 1
          @sub_info_handle = ctx.fancyline.sub_info.add do |ctx, yielder|
            lines = yielder.call(ctx)
            lines.unshift completion_info_string(ctx)
            lines
          end
        end

        move_entry ctx, -1
      end

      def stop(ctx : Context)
        ctx.fancyline.sub_info.disconnect @sub_info_handle
        ctx.clear_info
        ctx.draw
      end

      def completion_info_string(ctx)
        # Keep a margin of 2 columns on each side.
        width = ctx.tty.columns - 4
        avail = width

        words = Array(String).new # Mark the quick-select character
        @quick_select.each do |char, completion|
          word = completion.display_word
          avail -= word.size
          break if avail < 0

          if char
            pos = word.each_char.index{|c| c.downcase == char}.not_nil!
            char = word[pos] # The `char` may have a different case
            word = word.sub(pos, char.to_s.colorize.mode(:bold).to_s)
          end

          words << word
        end

        "  " + words.join("  ")
      end

      def handle(ctx : Context, char : Char) : Bool
        if char.control?
          handle_control(ctx, char)
        elsif char.alphanumeric?
          handle_quick_select(ctx, char)
        else
          super
        end
      end

      def handle_control(ctx, char)
        key = Key.read_control(char){ ctx.fancyline.input.read_char }
        case key
        when Key::Control::Tab
          move_entry ctx, +1
        when Key::Control::ShiftTab
          move_entry ctx, -1
        else
          ctx.stop_widget
          ctx.handle_control(key) if key
        end

        true
      end

      def handle_quick_select(ctx, char)
        ctx.stop_widget # Stop the widget anyway

        if completion = @quick_select[char.downcase]?
          apply_suggestion ctx, completion
          true
        else # If no match, proceed like normal
          false
        end
      end

      def move_entry(ctx, offset)
        @position = (@position + offset) % (@suggestions.size + 1)

        if @position >= @suggestions.size
          ctx.editor.line = @original_line
          ctx.editor.cursor = @original_cursor
        else
          apply_suggestion(ctx, @suggestions[@position])
        end
      end

      def apply_suggestion(ctx, completion)
        ctx.editor.line = @original_line
        ctx.editor.apply completion
      end

      def fetch_suggestions(ctx, range, word)
        list = ctx.fancyline.autocomplete.call(ctx, range, word)
        list.pop(list.size - MAX_COMPLETIONS) if list.size > MAX_COMPLETIONS
        @suggestions = list

        # Find unused character for quick-selection
        list.each do |entry|
          quick = entry.display_word.downcase.chars.find do |c|
            c.alphanumeric? && !@quick_select.has_key?(c)
          end

          @quick_select[quick] = entry if quick
        end
      end
    end
  end
end
