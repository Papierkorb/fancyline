class Fancyline
  abstract class Tty
    # Guesses the correct `Tty` implementation to use on *io*.
    def self.build(io)
      if io.tty?
        Tty::Vt100.new io
      else
        Tty::Dumb.new
      end
    end

    @colors : Bool

    def initialize
      @colors = get_has_colors
    end

    # Is this a dumb terminal?  A dumb terminal doesn't offer any capabilities
    # and acts more like a stream of bytes being thrown on the screen.  The case
    # for example the program is used through `popen(3)` like functionality.
    def dumb? : Bool
      false
    end

    # Does this terminal support colors?
    def colors? : Bool
      !dumb? && @colors
    end

    # Clears the current line and places the cursor at the beginning of it
    def prepare_line
      cursor_to_start
      clear_line
    end

    # Terminal columns at program start.
    abstract def columns : Int32

    # Terminal rows at program start.
    abstract def rows : Int32

    # Clears the current line, no matter on which column the cursor is
    abstract def clear_line

    # Moves the cursor to the start of the current line
    abstract def cursor_to_start

    # Moves the terminal cursor around relative to its position
    abstract def move_cursor(x, y)

    # Saves the cursor position, yields, and restores it afterwards.
    abstract def cursor_restore(&block)

    # Clears the screen and moves the cursor to the top left
    abstract def clear_screen

		# Enables the alternative buffer
		abstract def switch_to_alternate_screen

		# Disables the alternative buffer
		abstract def switch_from_alternate_screen

		# Switch to the alternate screen (think `less` or `man`) and restores
		# it afterwards.
		abstract def in_alternate_screen(&block)

    protected abstract def get_has_colors : Bool
  end
end
