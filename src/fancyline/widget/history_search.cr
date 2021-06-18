class Fancyline
  class Widget
    # Implements a simple history search feature.  Activated by hitting
    # "Ctrl-R", then accepts non-control input, Backspace and Up/Down.
    class HistorySearch < Widget
      getter! history : Fancyline::History?

      @original_line = ""
      @original_cursor = 0
      @position = 0
      @matches = [] of String
      getter! editor : Editor?

      @display_handle = Cute::ConnectionHandle.new(0)
      @sub_info_handle = Cute::ConnectionHandle.new(0)

      def start(ctx : Context)
        # Save the original line
        @original_line = ctx.editor.line
        @original_cursor = ctx.editor.cursor
        @history = ctx.fancyline.history
        @editor = ctx.create_editor(search_prompt)

        # Add our middlewares
        @display_handle = ctx.fancyline.display.add do |ctx, line, yielder|
          yielder.call ctx, line.gsub(needle_regex, &.colorize.mode(:reverse))
        end

        @sub_info_handle = ctx.fancyline.sub_info.add do |ctx, yielder|
          lines = yielder.call(ctx)
          lines.unshift editor
          lines
        end

        # Move our display middleware to the start
        ctx.fancyline.display.list.unshift ctx.fancyline.display.list.pop
      end

      def stop(ctx : Context)
        # Remove our middlewares
        ctx.fancyline.display.disconnect @display_handle
        ctx.fancyline.sub_info.disconnect @sub_info_handle
        ctx.clear_info # Force clearing of our sub info line
        ctx.draw
      end

      def handle(ctx : Context, char : Char) : Bool
        unless char.control?
          editor.put_char(char)
          update_results(ctx)
          return true
        end

        key = Key.read_control(char) { ctx.fancyline.input.read_char }
        case key
        when Key::Control::Backspace
          editor.remove_at_cursor -1
          update_results(ctx)
        when Key::Control::Up
          move_entry ctx, -1
        when Key::Control::Down
          move_entry ctx, +1
        when Key::Control::CtrlC
          ctx.stop_widget
          restore_original(ctx)
        else
          ctx.stop_widget
          ctx.handle_control(key) if key
        end

        true
      end

      def update_results(ctx)
        if editor.empty?
          @matches.clear
        else
          @matches = history.lines.select needle_regex
        end

        @position = 0
        editor.prompt = search_prompt
        move_entry ctx, -1
      end

      def search_prompt
        "Search #{-@position}/#{@matches.size}: "
      end

      def needle_regex
        needle = editor.line
        if needle.each_char.any?(&.uppercase?)
          /#{Regex.escape needle}/
        else
          /#{Regex.escape needle}/i
        end
      end

      def restore_original(ctx)
        ctx.editor.line = @original_line
        ctx.editor.cursor = @original_cursor
      end

      def move_entry(ctx, offset)
        @position = (@position + offset).clamp(-@matches.size, 0)

        if @position == 0
          restore_original(ctx)
        else
          ctx.editor.line = @matches[@position]
          ctx.editor.cursor = ctx.editor.line.size
        end
      end
    end
  end
end
