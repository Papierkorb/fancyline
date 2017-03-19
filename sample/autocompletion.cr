require "../src/fancyline"

# This sample demonstrates auto-completion with Fancyline using the
# "autocomplete" middleware.

fancy = Fancyline.new

puts "Hit Ctrl-D or Ctrl-C to end the demo."
puts "Hit Tab to start the completion."

# Add an "autocomplete" middleware to add custom completions.
fancy.autocomplete.add do |ctx, range, word, yielder|
  completions = yielder.call(ctx, range, word)

  # Simple completion: Replace the given range with a word
  completions << Fancyline::Completion.new(range, "Crystal")
  completions << Fancyline::Completion.new(range, "Ruby")

  # Long completions, like path names, would become hard to read really quick.
  # Instead, pass a third argument to use for display in the completion list.
  # When the user chooses that one, the second argument will be inserted.
  completions << Fancyline::Completion.new(range, "a/long/path", "path")

  completions
end

# Prompt the user
while line = fancy.readline("Command> ")
  puts "=> #{line.inspect}"
end
