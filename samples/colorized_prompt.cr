require "../../src/fancyline"

# Demonstration of colorized prompts.

fancy = Fancyline.new # Build a shell object
puts "Press Ctrl-C or Ctrl-D to quit."

loop do
  lprompt = "#{Dir.current} ❱❱❱ ".colorize(:blue).mode(:bold).to_s
  rprompt = "❰❰❰ #{Time.now}".colorize(:yellow).mode(:bold).to_s

  input = fancy.readline(lprompt, rprompt: rprompt)

  break if input.nil?
  puts "Got #{input}"
end
