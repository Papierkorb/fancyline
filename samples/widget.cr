require "../src/fancyline"

# This sample demonstrates building a custom widget to enhance the editing
# experience of our user.

fancy = Fancyline.new
puts "Hit Ctrl-D or Ctrl-C to end the demo."
puts "Hit Ctrl-F for a selection of faces to paste."

# Custom widget which upon start presents the user with a list of faces to
# choose from, which are then pasted at the cursor position.
class FacesWidget < Fancyline::Widget
  FACES = ["😁", "😭", "🙃"]
  @sub_info_handle = Cute::ConnectionHandle.new(0)

  def start(ctx)
    # Add a sub_info middleware to show the user options to choose from.
    # Store the handle so we can remove it later again in `#stop`.
    @sub_info_handle = ctx.fancyline.sub_info.add do |ctx, yielder|
      lines = yielder.call(ctx)

      options = FACES.map_with_index { |str, idx| "#{idx}: #{str}" }
      lines << "  " + options.join("  ")

      lines
    end
  end

  def stop(ctx)
    # On stop, remove our middleware and force a redraw later on.
    ctx.fancyline.sub_info.disconnect @sub_info_handle
    ctx.clear_info
  end

  def handle(ctx, char : Char) : Bool
    # The user sent us some input
    if choose = char.to_i?     # Try to read it as numeric
      if face = FACES[choose]? # Is there a matching face?
        # Apply a completion to the line buffer at the cursor position.
        range = ctx.editor.cursor...ctx.editor.cursor
        ctx.editor.apply Fancyline::Completion.new(range, face)
      end

      # Remove this widget now and tell the `Context` that we handled this
      # input.
      ctx.stop_widget
      true
    else
      # If it's not some numeric, stop this widget and proceed as usual.
      super
    end
  end
end

# Add a key binding to allow the user to launch our widget at any time.
fancy.actions.set Fancyline::Key::Control::CtrlF do |ctx|
  ctx.start_widget FacesWidget.new
end

while line = fancy.readline("Prompt> ")
  puts "=> #{line.inspect}"
end
