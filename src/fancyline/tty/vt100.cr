class Fancyline
  class Tty
    lib LibC
      struct Winsize
        ws_row : UInt16    #  rows, in characters
        ws_col : UInt16    #  columns, in characters
        ws_xpixel : UInt16 #  horizontal size, pixels
        ws_ypixel : UInt16 #  vertical size, pixels
      end

      IOC_OUT      = 0x40000000
      IOCPARM_MASK =     0x1fff
      TIOCGWINSZ   = IOC_OUT | ((sizeof(Winsize) & IOCPARM_MASK) << 16) | (('t'.ord) << 8) | 104
      fun ioctl(fd : Int32, cmd : UInt64, winsize : Winsize*) : Int32
    end

    # Implements control codes for VT-100 compatible terminal emulators.
    class Vt100 < Tty
      CLEAR_LINE = "\e[2K"
      CURSOR_TO_START = "\r"
      PREPARE_LINE = CURSOR_TO_START + CLEAR_LINE

      def initialize(@io : IO)
        super()
      end

      def winsize
        LibC.ioctl(0, LibC::TIOCGWINSZ, out winsize)
        winsize
      end

      def columns
        winsize.ws_col
      end
      
      def rows
        winsize.ws_row
      end

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
