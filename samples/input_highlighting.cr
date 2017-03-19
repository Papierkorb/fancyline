require "../src/fancyline"
require "colorize"

# This sample demonstrates how to add simple syntax-highlighting.
# We highlight a simplified version of Ruby code.
# For demonstration purposes, we feed each line into a `ruby` process to do
# something useful with the user-input.

fancy = Fancyline.new

puts "Hit Ctrl-D or Ctrl-C to end the demo."
puts "Hit Return to run the code through `ruby`."

# The code highlighter.
def highlight(snippet)
  in_string = false

  snippet.split(/\b/).flat_map do |word|
    if word[0]?.try(&.alphanumeric?)
      word
    else
      word.chars.map(&.to_s)
    end
  end.map do |word|
    if in_string
      in_string = !word.ends_with?('"')
      next word.colorize(:red).to_s
    end

    case word
    when /^"/ # Strings
      in_string = true
      word.colorize(:red)
    when /^[A-Z]+$/ # Constants
      word.colorize(:light_blue).mode(:underline)
    when /^[A-Z][a-zA-Z]+$/, /^[+-]?([0-9]|[0-9]+\.[0-9]+)$/ # Classes, numerics
      word.colorize(:light_blue)
    when /^[(){}\[\]]+$/ # Brackets
      word.colorize(:green)
    when /^[\w_]+$/ # Identifiers
      word.colorize(:light_yellow)
    when ";"
      word.colorize.mode(:bold)
    else # Anything else
      word
    end
  end.join
end

# Add a display middleware to add highlighting to the user input.
fancy.display.add do |ctx, line, yielder|
  yielder.call ctx, highlight(line)
end

begin
  while input = fancy.readline("Ruby> ")
    stdin = IO::Memory.new
    stdin.print "puts '=> ' + (#{input}).inspect"
    stdin.rewind
    ruby = Process.run("ruby", input: stdin, output: true, error: true)
  end
rescue err : Fancyline::Interrupt
  puts "Bye."
end
