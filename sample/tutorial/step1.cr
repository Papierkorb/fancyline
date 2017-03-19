require "../../src/fancyline"

# Step 1 of the usage tutorial:
#   A simple skeleton, which already works as a simple shell.

fancy = Fancyline.new # Build a shell object
puts "Press Ctrl-C or Ctrl-D to quit."

while input = fancy.readline("$ ") # Ask the user for input
  # Also note how the history already works!
  system(input) # And run it
end
