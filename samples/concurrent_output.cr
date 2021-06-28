require "../src/fancyline"
require "log"

# This sample demonstrates `Fancyline#grab_output` to output log lines while the
# user is able to use the prompt like normal.

fancy = Fancyline.new

Log.info {  "Hit Ctrl-D or Ctrl-C to end the demo." }

# Simulate a background task writing something onto standard output.
spawn do
  0.upto(Int64::MAX).each do |i|
    fancy.grab_output do # Grab the output
      Log.info {  "Running #{i} seconds..." } # Print something
    end

    sleep 1
  end
end

# Prompt the user like normal
while line = fancy.readline("Command> ")
  # You don't have to grab here, though it wouldn't break anything!
  Log.info {  "Got command #{line.inspect}" }
end
