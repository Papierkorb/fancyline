class Fancyline
  class Tty
    # Implements control codes for VT-100 compatible terminal emulators.
    class Vt100 < Tty
      CLEAR_LINE = "\e[2K"
      CURSOR_TO_START = "\r"
      PREPARE_LINE = CURSOR_TO_START + CLEAR_LINE

      def initialize(@io : IO)
        super()
      end

      # FIXME: Properly get the terminal dimensions, don't rely on environment
      #        variables that are outdated at the time of reading them.

      getter columns = ENV["COLUMNS"]?.try(&.to_i?) || 80
      getter rows = ENV["ROWS"]?.try(&.to_i?) || 25

      def prepare_line
        @io.print PREPARE_LINE
      end

      def clear_line
        @io.print CLEAR_LINE
      end

      def cursor_to_start
        @io.print CURSOR_TO_START
      end

      def move_cursor(x, y)
        if x < 0
          @io.print "\e[#{x.abs}D"
        elsif x > 0
          @io.print "\e[#{x.abs}C"
        end

        if y < 0
          @io.print "\e[#{y.abs}A"
        elsif y > 0
          @io.print "\e[#{y.abs}B"
        end
      end

      def cursor_restore
        @io.print "\e[s"
        yield
      ensure
        @io.print "\e[u"
      end

      def clear_screen
        @io.print "\e[2J\e[H"
      end

      protected def get_has_colors : Bool
        if term = ENV["TERM"]?
          term.ends_with?("colors")
        else
          false
        end
      end
    end
  end
end
