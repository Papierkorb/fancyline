require "../../src/fancyline"

# Step 5 of the usage tutorial:
#   We use the "autocomplete" middleware to add auto-completion to our shell!

fancy = Fancyline.new
puts "Press Ctrl-C or Ctrl-D to quit.  Press Ctrl-H for man page."
puts "Press Tab for path auto-completion."

# We're now adding the auto-completion itself.  For this tutorial, we only
# auto-complete paths.  If you wanted to improve this further, you could
# complete commands too.  Try to put it into its own autocomplete middleware.
fancy.autocomplete.add do |ctx, range, word, yielder|
  completions = yielder.call(ctx, range, word)

  # The `word` may not suffice for us here.  It'd be fine however for command
  # name completion.

  # Find the range of the current path name near the cursor.  This is rather
  # convoluted: First, we make sure that we have something like a path.
  prev_char = ctx.editor.line[ctx.editor.cursor - 1]?
  if !word.empty? || { '/', '.' }.includes?(prev_char)
    # Then we try to find where it begins and ends
    arg_begin = ctx.editor.line.rindex(' ', ctx.editor.cursor - 1) || 0
    arg_end = ctx.editor.line.index(' ', arg_begin + 1) || ctx.editor.line.size

    # We need that thing as range for the completion.
    # Don't forget to skip the space at the beginning too!
    range = (arg_begin + 1)...arg_end

    # And using that range we just built, we can find the path the user entered
    path = ctx.editor.line[range].strip
  end

  # Find suggestions and append them to the completions array.
  Dir["#{path}*"].each do |suggestion|
    base = File.basename(suggestion)
    suggestion += '/' if Dir.exists? suggestion

    # We pass the range that the completion would replace and the suggestion
    # that we would replace into.  We also pass the basename as display-word,
    # as a list like "foo  bar  baz" is much nicer to read than something like
    # "foo/bar/baz  foo/bar/foo"
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

while input = fancy.readline("$ ")
  system(input)
end
