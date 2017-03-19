require "spec"
require "../src/fancyline"

# Memory IO which masquerades as TTY capable device
class FakeTty < IO::Memory
  def tty?
    true
  end
end
