class Fancyline
  class Tty
    lib LibC
      struct Winsize
        ws_row    : ::LibC::UShort # rows, in characters
        ws_col    : ::LibC::UShort # columns, in characters
        ws_xpixel : ::LibC::UShort # horizontal size, pixels
        ws_ypixel : ::LibC::UShort # vertical size, pixels
      end

      {% unless flag?(:x86_64) && flag?(:darwin)%}
        puts "Warning: Tty::Vt100#winsize \
        is not supported on your platform."
      {% end %}

      IOC_OUT      = 0x40000000
      IOCPARM_MASK =     0x1fff
      TIOCGWINSZ   = IOC_OUT | ((sizeof(Winsize) & IOCPARM_MASK) << 16) | (('t'.ord) << 8) | 104      

      @[Raises]
      fun ioctl(fd : ::LibC::Int, request : ::LibC::ULong, ...) : ::LibC::Int
    end

    # Implements control codes for VT-100 compatible terminal emulators.
    class Vt100 < Tty
      CLEAR_LINE = "\e[2K"
      CURSOR_TO_START = "\r"
      PREPARE_LINE = CURSOR_TO_START + CLEAR_LINE

      def initialize(@io : IO)
        super()
      end

      # Currently always raises when not compiled with `x86_64` and `darwin` flags
      def winsize
        {% if flag?(:x86_64) && flag?(:darwin) %}      
          winsize = uninitialized LibC::Winsize
          LibC.ioctl(0, LibC::TIOCGWINSZ, pointerof(winsize))
          winsize
        {% else %}
          raise "#winsize not supported on your platform"
        {% end %}
      end

      def columns
        begin
          winsize.ws_col
        rescue
          ENV["COLUMNS"]?.try(&.to_i?) || 80
        end
      end
      
      def rows
        begin
          winsize.ws_row
        rescue
          ENV["ROWS"]?.try(&.to_i?) || 25
        end
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
