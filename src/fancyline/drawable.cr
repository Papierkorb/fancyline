class Fancyline
  # Module to create drawable objects, which can be used in sub_info
  # middlewares.
  module Drawable
    # Draws itself in the current line.  Only this line must be used.
    # The current line has been cleared already, and the cursor is at the
    # beginning of the line.
    abstract def draw(ctx : Context)
  end
end
