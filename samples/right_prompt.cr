require "../../src/fancyline"

# Demonstration of a RPROMPT.  The `rprompt` will be displayed on the right-hand
# end of the terminal window.

fancy = Fancyline.new # Build a shell object
puts "Press Ctrl-C or Ctrl-D to quit."

while input = fancy.readline("$ ", rprompt: "< Hi") # Ask the user for input
  # Also note how the history already works!
  system(input) # And run it
end
