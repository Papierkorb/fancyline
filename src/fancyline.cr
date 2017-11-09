require "cute" # https://github.com/Papierkorb/cute
require "colorize"
require "./fancyline/**"

# Readline-esque library with some fancy features.
#
# ## Quick usage
#
# A simple greeter can be built like this:
#
# ```crystal
# require "fancyline"
#
# fancy = Fancyline.new
# name = fancy.readline("Name: ")
# puts "Hello, #{name}"
# ```
#
# Have a look in the `samples/` directory for more!
class Fancyline

  # Raised when the user hit Ctrl-C (Default mapping)
  class Interrupt < Exception
  end

  # History of previous input
  getter history : History

  # Device to read input from
  getter input : IO

  # Device to write terminal output to
  getter output : IO

  # Key bindings (or "key map")
  getter actions : KeyAction

  # Currently active context, if any
  getter context : Context?

  # TTY control
  property tty : Tty

  def initialize(@input = STDIN, @output = STDOUT, tty : Tty? = nil)
    @history = History.new
    @actions = KeyAction.new
    @tty = tty || Fancyline::Tty.build(@output)
  end

  # Reads a line, showing the *prompt*.  If *history* is `true`, the input is
  # added to the `#history`.  Returns the input string, or `nil`, if the input
  # stream went EOF, this may happen when the user inputs `Ctrl-D`.  The
  # returned string does not end with a new-line, but surrounding whitespace as
  # input by the user is retained.
  #
  # If *rprompt* is given, it'll be displayed on the right-hand end of the
  # terminal.  If the users input comes near it (`Editor::RPROMPT_MARGIN`), it
  # will be hidden.  If no *rprompt* is given, none is shown.
  #
  # If this instance already has a context running it will raise.
  #
  # ## Ctrl-C, or an interrupt
  #
  # By default a key press of `Ctrl-C` (`^C`) will raise an `Interrupt`. Do not
  # confuse this with `SIGINT`, which is not raised by this method.  Nor is a
  # `SIGINT` sent by a different process caught or handled.
  #
  # To change the behaviour of raising `Interrupt`, change the mapping of it:
  # ```
  # fancyline.actions.set(Fancyline::Key::Control::CtrlC) do |ctx|
  #   ctx.reject! # Reject input, make `Fancyline#readline` return `nil`
  # end
  # ```
  def readline(prompt, rprompt : String? = nil, history = true) : String?
    ctx = Context.new(self, prompt)
    raise "Concurrent context is already open" if @context
    @context = ctx

    ctx.editor.rprompt = rprompt
    input_line = nil

    with_sync_output do
      with_raw_input do
        ctx.draw
        while char = @input.read_char
          ctx.handle char

          unless ctx.status.reading?
            input_line = ctx.destruct
            break
          end

          ctx.draw
        end
      end
    end

    @history.add input_line if history && input_line
    input_line
  ensure
    @context = nil
  end

  # Grabs the output: If there's a running prompt, clears it from the screen.
  # Then `yield`s with no arguments.  Upon returning, redraws the prompt.
  # If there's no running prompt `yield`s.
  #
  # Use this method to write data onto the screen while the user is editing
  # the prompt.  Such data could be log output while letting the user give
  # commands to a running process.
  #
  # The redrawing of the prompt happens in an `ensure` block.  Thus, if the
  # block raises, the prompt will be redrawn anyway.
  #
  # See `sample/concurrent_output.cr` for sample code.
  def grab_output
    if ctx = @context
      begin
        ctx.editor.clear_prompt
        ctx.clear_info
        yield
      ensure
        ctx.draw
      end
    else
      yield
    end
  end

  Cute.middleware def autocomplete(ctx : Context, range : Range(Int32, Int32),
                                   word : String) : Array(Completion)
    Array(Completion).new
  end

  # Middleware to modify the display before outputting it onto the terminal.
  Cute.middleware def display(ctx : Context, line : String) : String
    line
  end

  # Middleware to produce information for the *ctx*
  Cute.middleware def sub_info(ctx : Context) : Array(String | Drawable)
    Array(String | Drawable).new
  end

  protected def with_raw_input
    input = @input
    if input.responds_to?(:raw) && input.tty?
      input.raw{ yield }
    else
      yield
    end
  end

  protected def with_sync_output
    output = @output
    if output.is_a?(IO::Buffered)
      before = output.sync?

      begin
        output.sync = true
        yield
      ensure
        output.sync = before
      end
    else
      yield
    end
  end
end
