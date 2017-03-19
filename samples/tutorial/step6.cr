require "../../src/fancyline"

# Step 6 of the usage tutorial:
#   We're wrapping things up.  We're adding a persistant command history.
#   Second, we're now finally catching `Fancyline::Interrupt` so our user can
#   hit Ctrl-C like in any other shell.
#
#   You'll find these changes near the end of this file, around the `while` loop
#   we've created long ago and never really changed until now :)
#
#   In case you're wondering, the history will be stored in `history.log` in the
#   current working directory.

fancy = Fancyline.new
puts "Press Ctrl-C or Ctrl-D to quit.  Press Ctrl-H for man page."
puts "Press Tab for path auto-completion."

fancy.autocomplete.add do |ctx, range, word, yielder|
  completions = yielder.call(ctx, range, word)

  # The `word` may not suffice for us here.  It'd be fine however for command
  # name completion.

  # Find the range of the current path name near the cursor.
  prev_char = ctx.editor.line[ctx.editor.cursor - 1]?
  if !word.empty? || { '/', '.' }.includes?(prev_char)
    arg_begin = ctx.editor.line.rindex(' ', ctx.editor.cursor - 1) || 0
    arg_end = ctx.editor.line.index(' ', arg_begin + 1) || ctx.editor.line.size
    range = (arg_begin + 1)...arg_end
    path = ctx.editor.line[range].strip
  end

  # Find suggestions and append them to the completions array.
  Dir["#{path}*"].each do |suggestion|
    base = File.basename(suggestion)
    suggestion += '/' if Dir.exists? suggestion
    completions << Fancyline::Completion.new(range, suggestion, base)
  end

  completions
end

def get_command(ctx)
  line = ctx.editor.line
  cursor = ctx.editor.cursor.clamp(0, line.size - 1)
  pipe = line.rindex('|', cursor)
  line = line[(pipe + 1)..-1] if pipe

  line.split.first?
end

fancy.sub_info.add do |ctx, yielder|
  lines = yielder.call(ctx)

  if command = get_command(ctx)
    help_line = `whatis #{command} 2> /dev/null`.lines.first?
    lines << help_line if help_line
  end

  lines
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

#
HISTFILE = "#{Dir.current}/history.log"

# If our HISTFILE exists, read it into the history.
if File.exists? HISTFILE # Does it exist?
  puts "  Reading history from #{HISTFILE}"

  File.open(HISTFILE, "r") do |io| # Open a handle
    fancy.history.load io # And load it
  end
end

begin # Get rid of stacktrace on ^C
  while input = fancy.readline("$ ")
    system(input)
  end

  # Just rescue from `Fancyline::Interrupt`, say good-bye and we're done.
rescue err : Fancyline::Interrupt
  puts "Bye."
end

# Now we have to save our history again
File.open(HISTFILE, "w") do |io| # So open it writable
  fancy.history.save io # And save.  That's it.
end
