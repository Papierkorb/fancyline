require "../src/fancyline"

# This sample demonstrates `Fancyline#grab_output` to output log lines while the
# user is able to use the prompt like normal.

fancy = Fancyline.new
puts "Hit Ctrl-D or Ctrl-C to end the demo."
puts "Hit Ctrl-U to upcase the current prompt input."

# Add a binding for Ctrl-U to upcase the current input
fancy.actions.set Fancyline::Key::Control::CtrlU do |ctx|
  ctx.editor.line = ctx.editor.line.upcase
end

while line = fancy.readline("Prompt> ")
  puts "=> #{line.inspect}"
end
