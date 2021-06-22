class Fancyline
  # Mapping for key actions.  Usually accessed through `Fancyline#actions`.
  class KeyAction
    alias Handler = Proc(Context, Nil)

    # Default key bindings.  Make sure to bind keys like `Key::Control::Return`
    # or `Key::Control::CtrlC`.  Else, the user may not have any way to exit
    # a prompt.
    DEFAULT = {
      Key::Control::CtrlC => ->(ctx : Context) do
        raise Interrupt.new
      end,
      Key::Control::Return => ->(ctx : Context) do
        ctx.accept!
      end,
      Key::Control::CtrlO => ->(ctx : Context) do
        ctx.accept!
      end,
      Key::Control::Backspace => ->(ctx : Context) do
        ctx.editor.remove_at_cursor -1
      end,
      # Add ^H as backspace to cover all possible keycodes
      # see https://invisible-island.net/xterm/xterm.faq.html#xterm_erase
      # and https://unix.stackexchange.com/questions/303016/backspace-not-working-in-kali-linux-terminal-hosted-on-backbox-using-virtual-box
      Key::Control::CtrlH => ->(ctx : Context) do
        ctx.editor.remove_at_cursor -1
      end,
      Key::Control::Delete => ->(ctx : Context) do
        ctx.editor.remove_at_cursor +1
      end,
      Key::Control::Left => ->(ctx : Context) do
        ctx.editor.move_cursor -1
      end,
      Key::Control::Right => ->(ctx : Context) do
        ctx.editor.move_cursor +1
      end,
      Key::Control::Home => ->(ctx : Context) do
        ctx.editor.move_cursor Int32::MIN
      end,
      Key::Control::End => ->(ctx : Context) do
        ctx.editor.move_cursor Int32::MAX
      end,
      Key::Control::CtrlA => ->(ctx : Context) do
        ctx.editor.move_cursor Int32::MIN
      end,
      Key::Control::CtrlE => ->(ctx : Context) do
        ctx.editor.move_cursor Int32::MAX
      end,
      Key::Control::CtrlD => ->(ctx : Context) do
        ctx.reject! if ctx.editor.empty?
      end,
      Key::Control::CtrlU => ->(ctx : Context) do
        ctx.editor.clear
      end,
      Key::Control::CtrlL => ->(ctx : Context) do
        ctx.tty.clear_screen
      end,
      Key::Control::Up => ->(ctx : Context) do
        ctx.start_widget(Widget::History.new)
      end,
      Key::Control::CtrlR => ->(ctx : Context) do
        ctx.start_widget(Widget::HistorySearch.new)
      end,
      Key::Control::Tab => ->(ctx : Context) do
        ctx.start_widget(Widget::Completion.new)
      end,
    } of Key::Control => Handler

    # The key action mapping
    property mapping : Hash(Key::Control, Handler)

    # Initializes the mapping to a clone of the `DEFAULT` one.
    def initialize(@mapping = DEFAULT.dup)
    end

    # Delegates to `#mapping`.
    delegate :[], :[]=, :[]?, to: @mapping

    # Sets a mapping for *key* to run the given block upon hitting it.
    # Replaces an existing mapping for *key* if any exists.
    def set(key : Key::Control, &block : Handler)
      @mapping[key] = block
    end
  end
end
