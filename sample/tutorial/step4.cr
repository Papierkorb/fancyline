require "../../src/fancyline"

# Step 4 of the usage tutorial:
#   We learn about the "sub_info" middleware, which lets us display information
#   under the prompt about the prompt.  We use this feature to describe the
#   currently input command to the user.

fancy = Fancyline.new
puts "Press Ctrl-C or Ctrl-D to quit.  Press Ctrl-H for man page."

def get_command(ctx)
  line = ctx.editor.line
  cursor = ctx.editor.cursor.clamp(0, line.size - 1)
  pipe = line.rindex('|', cursor)
  line = line[(pipe + 1)..-1] if pipe

  line.split.first?
end

# Now, we add the middleware itself.  Middlewares are called for each key input,
# a good improvement to this one would be caching the result of "whatis".
fancy.sub_info.add do |ctx, yielder|
  lines = yielder.call(ctx) # First run the next part of the middleware chain

  if command = get_command(ctx) # Grab the command
    # Use `whatis(1)` to get information about the command
    help_line = `whatis #{command} 2> /dev/null`.lines.first?
    lines << help_line if help_line # Display it if we got something
  end

  lines # Return the lines so far
end

fancy.actions.set Fancyline::Key::Control::CtrlH do |ctx|
  if command = get_command(ctx)
    system("man #{command}") # And open the man-page of it
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
