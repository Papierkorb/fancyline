class Fancyline
  class Tty
    lib LibC
      struct Winsize
        ws_row : ::LibC::UShort    # rows, in characters
        ws_col : ::LibC::UShort    # columns, in characters
        ws_xpixel : ::LibC::UShort # horizontal size, pixels
        ws_ypixel : ::LibC::UShort # vertical size, pixels
      end

      {% if flag?(:x86_64) && flag?(:darwin) %}
        IOC_OUT      = 0x40000000
        IOCPARM_MASK =     0x1fff
        TIOCGWINSZ   = IOC_OUT | ((sizeof(Winsize) & IOCPARM_MASK) << 16) | (('t'.ord) << 8) | 104
      {% elsif flag?(:linux) %}
        TIOCGWINSZ = 0x5413 # Per /usr/include/asm-generic/ioctls.h
      {% else %}
        {% puts "Warning: Tty::Vt100#winsize is not supported on your platform." %}
      {% end %}

      fun ioctl(fd : ::LibC::Int, request : ::LibC::ULong, ...) : ::LibC::Int
    end

    # Implements control codes for VT-100 compatible terminal emulators.
    class Vt100 < Tty
      CLEAR_LINE      = "\e[2K"
      CURSOR_TO_START = "\r"
      PREPARE_LINE    = CURSOR_TO_START + CLEAR_LINE

      def initialize(@io : IO)
        super()
      end

      # Currently always returns nil when not compiled with `x86_64` and `darwin` flags
      def winsize
        {% if LibC.has_constant?("TIOCGWINSZ") %}
          winsize = uninitialized LibC::Winsize
          if LibC.ioctl(0, LibC::TIOCGWINSZ, pointerof(winsize)) != -1
            winsize
          else
            nil
          end
        {% else %}
          nil
        {% end %}
      end

      def columns : Int32
        winsize.try(&.ws_col.to_i) || ENV["COLUMNS"]?.try(&.to_i?) || 80
      end

      def rows : Int32
        winsize.try(&.ws_row.to_i) || ENV["ROWS"]?.try(&.to_i?) || 25
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
