class Fancyline
  # Contains a completion, which consists of a replacement range and the
  # replacement word.
  struct Completion
    # Replacement range in the line buffer
    getter range : Range(Int32, Int32)

    # Word to replace into the range
    getter word : String

    # Word to display in the completion suggestion list.
    # If none given, defaults to `#word`.
    getter display_word : String

    def initialize(@range, @word, display_word = nil)
      @display_word = display_word || @word
    end
  end
end
