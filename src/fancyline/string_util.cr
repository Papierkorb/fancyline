class Fancyline
  # String helpers
  module StringUtil
    extend self

    # Dimensions of a string when displayed on a terminal.  Stores the `#rows`,
    # the `#columns`, and the count of human-visible `#characters`.
    #
    # `#rows` is always at least 1 (Even for an empty string).
    # `#columns` is the size of the longest line in the string.
    record Dimension,
      rows : Int32,
      columns : Int32,
      characters : Int32

    # Maximum size of a tab on screen in characters
    TAB_SIZE = 8

    # Returns the size of `str` on the terminal:
    #  * Does not count escape sequences
    #  * Counts tabs as up to `TAB_SIZE` characters
    #  * Handles newlines
    #  * Newline is not counted as character
    #
    # Returns a `Dimension` of 0 rows and 0 columns if *str* is `nil`.
    def terminal_size(str : String?) : Dimension
      return Dimension.new(0, 0, 0) if str.nil?

      columns = 0
      rows = 1
      size = 0
      cur_line = 0
      pos = 0

      while chr = str[pos]?
        case chr
        when '\n'
          columns = { cur_line, columns }.max
          cur_line = 0
          rows += 1
        when '\t'
          spaces = TAB_SIZE - cur_line % TAB_SIZE
          spaces = TAB_SIZE if spaces == 0
          cur_line += spaces
          size += spaces
        when '\e'
          pos = end_of_escape_sequence(str, pos)
        else
          cur_line += 1
          size += 1
        end

        pos += 1
      end

      Dimension.new rows, { cur_line, columns }.max, size
    end

    # Returns a sub-string of *str* of `[offset...(offset+length)]`, retaining
    # surrounding coloring.
    #
    # Usage is like `String#[]`, except that escape sequences are **skipped**
    # in the character counting.  Example:
    #
    # ```
    # StringUtil.terminal_sub("\e[1mfoobar\e[0m", 3, 3) #=> "\e[1mbar\e[0m"
    # ```
    #
    # Note: This method is meant to be used with color-changing escape
    #       sequences only.
    def terminal_sub(str : String, offset, length) : String?
      return nil if offset >= str.size

      trailing = ""
      char_pos = 0 # Counted characters that are not escape-sequences.
      pos = 0 # Position in string

      end_offset = offset + length
      range = offset...end_offset

      String.build do |b|
        while char = str[pos]?
          if char == '\e'
            new_pos = end_of_escape_sequence(str, pos)
            append_to_builder(b, str, pos, new_pos)
            pos = new_pos + 1
          else
            b << char if range.includes? char_pos
            char_pos += 1
            pos += 1
          end
        end
      end
    end

    # Appends `str[offset..end_offset]` to *b* without temporary buffers.
    private def append_to_builder(b, str, offset, end_offset)
      byte_begin = str.char_index_to_byte_index(offset)
      byte_end = str.char_index_to_byte_index(end_offset)

      raise IndexError.new("#{offset}..#{end_offset} is out of bounds") if byte_begin.nil? || byte_end.nil?

      b.write str.to_slice[byte_begin, byte_end - byte_begin + 1]
    end

    # Finds the end-position of the escape sequence starting at *offset* in
    # *str*.
    private def end_of_escape_sequence(str, offset) : Int32
      offset += 1 if str[offset]? == '\e'
      offset += 1 if str[offset]? == '['

      while char = str[offset]?
        if ('@'..'~').includes?(char)
          break
        else
          offset += 1
        end
      end

      offset
    end
  end
end
