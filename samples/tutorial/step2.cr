require "../../src/fancyline"

# Step 2 of the usage tutorial:
#   We use the `display` middleware of `Fancyline` to add syntax-highlighting
#   to the prompt.

fancy = Fancyline.new
puts "Press Ctrl-C or Ctrl-D to quit."

# Add a display middleware to add highlighting.  Make sure that you don't modify
# the visual length of *line*, else cursor won't match up with its real
# position.
fancy.display.add do |ctx, line, yielder|
  # We underline command names
  line = line.gsub(/^\w+/, &.colorize.mode(:underline))
  line = line.gsub(/(\|\s*)(\w+)/) do
    "#{$1}#{$2.colorize.mode(:underline)}"
  end

  # And turn --arguments green
  line = line.gsub(/--?\w+/, &.colorize(:green))

  # Then we call the next middleware with the modified line
  yielder.call ctx, line
end

while input = fancy.readline("$ ")
  system(input)
end
