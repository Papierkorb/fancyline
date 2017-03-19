class Fancyline
  # Base class for widgets.  A widget can intercept key inputs to temporarily
  # take control of parts of a running prompt.  Usually, a widget is enabled
  # by certain user-input: Hitting the "Up" key starts the `Widget::History`,
  # while hitting "Tab" starts `Widget::Autocomplete`.
  #
  # To create a custom widget, add a key binding (`Fancyline#actions`) which
  # then calls `Context#start_widget`.  The context will then proceed to
  # call `Widget#start`, and calls `Widget#handle` to handle input.  When the
  # widget is removed (for whatever reason), `Widget#stop` is called.
  #
  # You can find an usage sample in `samples/widget.cr`.  Another good built-in
  # widget to study is `Fancyline::Widget::History`.
  abstract class Widget
    # Called when the widget is activated.
    def start(ctx : Context)
    end

    # Called when the widget is removed.
    def stop(ctx : Context)
    end

    # Called on user-input.  Return `true` if you handeled the input, return
    # `false` to handle it as normal input by the `Context`.
    #
    # The default implementation calls `Context#stop_widget` to remove itself,
    # and returns `false`.
    def handle(ctx : Context, char : Char) : Bool
      ctx.stop_widget
      false
    end
  end
end
