require "../../src/fancyline"

# Step 3 of the usage tutorial:
#   We add a custom key binding: When the user hits `Ctrl-O` (Or `^O`), we want
#   to open the man-page of the currently input command.

fancy = Fancyline.new
puts "Press Ctrl-C or Ctrl-D to quit.  Press Ctrl-O for man page."

# This method grabs the current method from the line buffer with respect to the
# cursor position.
def get_command(ctx)
  line = ctx.editor.line
  cursor = ctx.editor.cursor.clamp(0, line.size - 1)
  pipe = line.rindex('|', cursor)
  line = line[(pipe + 1)..-1] if pipe

  line.split.first?
end

# Listen for `Ctrl-H`
fancy.actions.set Fancyline::Key::Control::CtrlO do |ctx|
  if command = get_command(ctx) # Figure out the current command
    system("man #{command}")    # And open the man-page of it
  end
end

fancy.display.add do |ctx, line, yielder|
  line = line.gsub(/^\w+/, &.colorize.mode(:underline))
  line = line.gsub(/(\|\s*)(\w+)/) do
    "#{$1}#{$2.colorize.mode(:underline)}"
  end

  line = line.gsub(/--?\w+/, &.colorize(:green))
  yielder.call ctx, line
end

while input = fancy.readline("$ ")
  system(input)
end
