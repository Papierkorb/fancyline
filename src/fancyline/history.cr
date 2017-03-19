class Fancyline
  # Manages the input history
  class History
    # Default value of maximum history size
    DEFAULT_MAX_SIZE = 1_000

    # Default ignore prefix
    DEFAULT_IGNORE_PREFIX = " "

    # Lines in the history.  The first entry is the oldest.  Maximum size can
    # be controlled through `#max=`
    getter lines : Array(String)

    # Max count of history entries to keep
    property max : Int32

    # If a line to add starts with this string, it's not recorded.
    property ignore_prefix : String = DEFAULT_IGNORE_PREFIX

    def initialize(@max : Int32 = DEFAULT_MAX_SIZE)
      @lines = Array(String).new
    end

    # Adds *line* to the history, except if:
    #  * *line* is nil
    #  * *line* is empty
    #  * *line* only consists of blank characters
    #  * *line* starts with the `#ignore_prefix`
    #  * *line* matches the most recent entry in the history
    #
    # Returns `true` if the line was added.
    def add(line : String?) : Bool
      return false if ignore? line

      @lines.shift if @lines.size >= @max
      @lines << line
      true
    end

    # Returns `true` if *line* should be ignored.  See `#add` for all rules.
    def ignore?(line : String?)
      return true if line.nil?

      line.blank? || line.starts_with?(@ignore_prefix) || @lines.last? == line
    end

    # Replaces the current history with the lines from *io*.
    # *io* is read till the end, with later lines representing more-recent
    # history entries.
    def load(io : IO)
      lines = Array(String).new

      while line = io.gets
        lines << line unless line.blank?
      end

      @lines = lines # Only keep max count of lines
      @lines = lines[(lines.size - @max)..-1] if lines.size > @max
    end

    # Writes the history into *io*.
    def save(io : IO)
      @lines.each do |line|
        io.puts line
      end
    end
  end
end
