require "../src/fancyline"

# Demonstration of multi-line prompts.

fancy = Fancyline.new # Build a shell object
puts "Press Ctrl-C or Ctrl-D to quit."

loop do
  top_bar = "═" * (fancy.tty.columns - 2)

  lprompt = "╔#{top_bar}╗\r\n╚═══ #{"❱❱❱".colorize(:yellow)} "
  rprompt = "#{"❰❰❰".colorize(:yellow)} ═══╝"

  input = fancy.readline(lprompt, rprompt: rprompt)

  break if input.nil?
  puts "Got #{input}"
end
