class Fancyline
  class Tty
    # Implementation for dumb terminals.  Mostly empty implementations.
    class Dumb < Tty
      def dumb? : Bool
        true
      end

      def columns
        80
      end

      def rows
        25
      end

      def clear_line
      end

      def cursor_to_start
      end

      def move_cursor(x, y)
      end

      def cursor_restore
        yield
      end

      def clear_screen
      end

      protected def get_has_colors : Bool
        false
      end
    end
  end
end
