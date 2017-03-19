require "../src/fancyline"

# This sample demonstrates using the "sub_info" middleware to provide the user
# with more information while editing the prompt.

fancy = Fancyline.new
puts "Hit Ctrl-D or Ctrl-C to end the demo."

# Add a sub_info middleware showing the word at the cursor
fancy.sub_info.add do |ctx, yielder|
  lines = yielder.call(ctx) # Daisy chain

  # Just insert the line(s) to show into the array and return it.
  # Make sure that the string does not contain any newlines itself.
  lines << "Current word: #{ctx.editor.word_at_offset.inspect}"
  lines
end

while line = fancy.readline("Prompt> ")
  puts "=> #{line.inspect}"
end
