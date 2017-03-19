class Fancyline
  # Host for ASCII key sequence code, which does its best to figure out what
  # the user just typed.
  module Key
    enum Control
      Backspace = 127
      Return = 13 # Same as Ctrl-M
      AltReturn
      Tab = 9
      ShiftTab
      Escape = 27

      CtrlA = 1
      CtrlB = 2
      CtrlC = 3
      CtrlD = 4
      CtrlE = 5
      CtrlF = 6
      CtrlG = 7
      CtrlH = 8
      # CtrlI = 9 # That's Tab
      CtrlJ = 10
      CtrlK = 11
      CtrlL = 12
      # CtrlM = 13 # Doesn't exist, collides with `Return`
      CtrlN = 14
      CtrlO = 15
      CtrlP = 16
      CtrlQ = 17
      CtrlR = 18
      CtrlS = 19
      CtrlT = 20
      CtrlU = 21
      CtrlV = 22
      CtrlW = 23
      CtrlX = 24
      CtrlY = 25
      CtrlZ = 26

      # Never used in code, just a hint for Crystal to not create collisions
      # while assign enum numbers for the following, unnumbered fields.
      FixAutonumbering = 1000

      Home
      End
      PageUp
      PageDown
      Insert
      Delete

      Up
      Down
      Left
      Right
      ShiftUp
      ShiftDown
      ShiftLeft
      ShiftRight
      CtrlUp
      CtrlDown
      CtrlLeft
      CtrlRight
      AltUp
      AltDown
      AltLeft
      AltRight

      F1
      F2
      F3
      F4
      F5
      F6
      F7
      F8
      F9
      F10
      F11
      F12

      AltA # = 27 97
      AltB # = 27 98
      AltC #      ...
      AltD
      AltE
      AltF
      AltG
      AltH
      AltI
      AltJ
      AltK
      AltL
      AltM
      AltN
      AltO
      AltP
      AltQ
      AltR
      AltS
      AltT
      AltU
      AltV
      AltW
      AltX
      AltY
      AltZ
    end

    # Reads a `Control` input from *char*.  If an escape sequence was detected,
    # calls the given block for the next `Char?`.
    def self.read_control(char : Char) : Control?
      {% begin %}
      case char.ord
      when Control::Escape.value
        read_escape_sequence(char){ yield }
      {% for key in %i[
        Backspace Tab Return
        CtrlA CtrlB CtrlC CtrlD CtrlE CtrlF CtrlG CtrlH CtrlJ CtrlK CtrlL CtrlN
        CtrlO CtrlP CtrlQ CtrlR CtrlS CtrlT CtrlU CtrlV CtrlW CtrlX CtrlY CtrlZ
        ] %}
        when Control::{{ key.id }}.value
          Control::{{ key.id }}
      {% end %}
      else
        nil
      end
      {% end %}
    end

    # If you thought `.read_control` was bad, prepare yourself.  Escape
    # sequences are a mess.  Terminals don't really agree which sequence
    # is what key.  At least there aren't collisions yet (as far I know), but
    # you may find a bunch of seemingly duplicate sequences.  Uargh.
    # Worse, if you only hit "ESC", then the terminal sends us '\e' == 27,
    # and nothing else.  Too bad that's also the start of all escape-sequences
    # (Hence their name).  If you ever wondered why terminal programs take a
    # moment to respond when you're hitting ESC, that's why.
    #
    # At least on linux (And others?), there's the `showkey` tool, which greatly
    # helps identifying the sent sequences.  Call it like `showkey --ascii` to
    # get it to output the ASCII escape-sequences.
    #
    # Maybe one should make this configurable.  Or maybe no one really cares
    # enough.  Here's hoping that as far as terminals go, if new emerge they'll
    # copy the keymap of existing ones.
    #
    # This is bad, but making it completely configurable, reading the mapping
    # from some file or so, wouldn't be fun either.

    private def self.read_escape_sequence(char)
      case yield.try(&.ord)
      when 13 then Control::AltReturn
      when 79 # F-keys
        case yield.try(&.ord)
        when 80 then Control::F1
        when 81 then Control::F2
        when 82 then Control::F3
        when 83 then Control::F4
        end
      when 91 # Movement and F-keys
        case yield.try(&.ord)
        when 49
          case yield.try(&.ord)
          when 53
            yield
            Control::F5
          when 55
            yield
            Control::F6
          when 56
            yield
            Control::F7
          when 57
            yield
            Control::F8
          when 59
            case yield.try(&.ord)
            when 50
              case yield.try(&.ord)
              when 65 then Control::ShiftUp
              when 66 then Control::ShiftDown
              when 67 then Control::ShiftRight
              when 68 then Control::ShiftLeft
              else
                nil
              end
            when 51
              case yield.try(&.ord)
              when 65 then Control::AltUp
              when 66 then Control::AltDown
              when 67 then Control::AltRight
              when 68 then Control::AltLeft
              else
                nil
              end
            when 53
              case yield.try(&.ord)
              when 65 then Control::CtrlUp
              when 66 then Control::CtrlDown
              when 67 then Control::CtrlRight
              when 68 then Control::CtrlLeft
              else
                nil
              end
            else
              nil
            end
          else
            Control::Home
          end
        when 50
          case yield.try(&.ord)
          when 48
            yield
            Control::F9
          when 49
            yield
            Control::F10
          when 51
            yield
            Control::F11
          when 52
            yield
            Control::F12
          else
            Control::Insert
          end
        when 51
          yield
          Control::Delete
        when 52
          yield
          Control::End
        when 53
          yield
          Control::PageUp
        when 54
          yield
          Control::PageDown
        when 65 then Control::Up
        when 66 then Control::Down
        when 67 then Control::Right
        when 68 then Control::Left
        when 70 then Control::End
        when 72 then Control::Home
        when 90 then Control::ShiftTab
        end
      # Alt-Letter keys
      when 97 then Control::AltA
      when 98 then Control::AltB
      when 99 then Control::AltC
      when 100 then Control::AltD
      when 101 then Control::AltE
      when 102 then Control::AltF
      when 103 then Control::AltG
      when 104 then Control::AltH
      when 105 then Control::AltI
      when 106 then Control::AltJ
      when 107 then Control::AltK
      when 108 then Control::AltL
      when 109 then Control::AltM
      when 110 then Control::AltN
      when 111 then Control::AltO
      when 112 then Control::AltP
      when 113 then Control::AltQ
      when 114 then Control::AltR
      when 115 then Control::AltS
      when 116 then Control::AltT
      when 117 then Control::AltU
      when 118 then Control::AltV
      when 119 then Control::AltW
      when 120 then Control::AltX
      when 121 then Control::AltY
      when 122 then Control::AltZ
      end
    end
  end
end
