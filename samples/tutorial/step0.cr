require "../../src/fancyline"

# Step 0 of the usage tutorial:
#   We build a greeter.

fancy = Fancyline.new # Build a shell object

fancy = Fancyline.new            # Build a shell object
input = fancy.readline("Name: ") # Show the prompt
puts "Hello, #{input}!"
