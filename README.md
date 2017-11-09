# Fancyline [![Build Status](https://travis-ci.org/Papierkorb/fancyline.svg?branch=master)](https://travis-ci.org/Papierkorb/fancyline)

<!-- Hello reader: If you're editing this file, please use two spaces after each
     sentence to improve readability of the raw file - Thanks! -->

Readline-esque library with fancy features!

## Compared with Readline

|                           | Fancyline  | Readline     |
|-------------------------- | ---------- | ------------ |
| Uses Readline config      | No         | Yes          |
| Code style                | OOP        | Imperative   |
| Autocompletion            | Yes        | Yes          |
| Input highlighting        | Yes        | No           |
| Can show further info     | Yes        | No           |
| Right-side prompt         | Yes        | Hacky        |
| Multi-line prompt         | Yes        | Manually     |
| Blocking behaviour        | Only Fiber | Whole Thread |
| License                   | MPL-2      | GPL          |

## Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  fancyline:
    github: Papierkorb/fancyline
```

## Tutorial

Let's build a simple system shell.  We want it to do syntax highlighting, do
tab-autocompletion, and show a quicktip about the current command.  We're
focusing on the REPL part, so we'll stick to using `system()` to use `/bin/sh`
to handle pipes etc..

Don't want to paste all of these yourself?  Fear not, check out
[samples/tutorial/](https://github.com/Papierkorb/fancyline/tree/master/samples/tutorial).

There are more general samples in
[samples/](https://github.com/Papierkorb/fancyline/tree/master/samples).

### Step 0: Most basic usage

Let's start with something simple: A greeter.  The user is asked for a name,
and that name is then greeted.  All we need to do is createing a `Fancyline`
instance and then calling `#readline` on it with our prompt.

```crystal
require "fancyline"

fancy = Fancyline.new # Build a shell object
input = fancy.readline("Name: ") # Show the prompt
puts "Hello, #{input}!"
```

[Complete source](https://github.com/Papierkorb/fancyline/tree/master/samples/tutorial/step0.cr)

### Step 1: The REPL skeleton

The skeleton of a REPL (**R**ead **E**valuate **P**rint **L**oop) is really
what it says on the tin: A loop, which accepts input, runs it, and then prints
the output.  Replace the last file with the following:

```crystal
require "fancyline"

fancy = Fancyline.new # Build a shell object
puts "Press Ctrl-C or Ctrl-D to quit."

while input = fancy.readline("$ ") # Ask the user for input
  system(input) # And run it
end
```

Now we can run commands and have a command history.  Pretty decent for a few
lines.

Possible improvement: Make `cd` work by implementing it.  This series will not.

[Complete source](https://github.com/Papierkorb/fancyline/tree/master/samples/tutorial/step1.cr)

### Step 2: Simple syntax-highlighting

Many people seem to enjoy having their shell do some syntax-highlighting to
show the command, arguments, or similar.  So let's add it to our shell!  We use
the `display` middleware of Fancyline, which is called with the line buffer and
can then add colors to it.  Make sure to not change the visual size of the line.

Just add this code snippet to your source file:

```crystal
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
```

Now, everytime the user hits a key, Fancyline will render the line buffer, which
calls all `display` middlewares in order.

Possible improvement: Try to add better highlighting.

[Complete source](https://github.com/Papierkorb/fancyline/tree/master/samples/tutorial/step2.cr)

### Step 3: Custom key bindings

One thing that's really useful is being able to pull up the man-page of the
command you're currently working on without having to type it yourself.  We add
a key-binding for `Ctrl-H` (`^H`) to do this for us:

```crystal
def get_command(ctx)
  line = ctx.editor.line
  cursor = ctx.editor.cursor.clamp(0, line.size - 1)
  pipe = line.rindex('|', cursor)
  line = line[(pipe + 1)..-1] if pipe

  line.split.first?
end

fancy.actions.set Fancyline::Key::Control::CtrlH do |ctx|
  if command = get_command(ctx) # Figure out the current command
    system("man #{command}") # And open the man-page of it
  end
end
```

If you look at line **3**, you see we're clamping the value of `ctx.editor.cursor` to
the range of `[0...line.size]`.  Fancyline allows the cursor to be at
`line.size`, so just after the line buffer, allowing the user to append
characters at the end of it.  But Crystal doesn't like that and may raise an
exception if the cursor is currently at the end of the line.

Now, run the program, type a command, and hit `Ctrl-H` to show the man-page.

Possible improvement: Add a key-binding which saves the last line as
`script.sh`.

[Complete source](https://github.com/Papierkorb/fancyline/tree/master/samples/tutorial/step3.cr)

### Step 4: Showing information below the prompt

Next we learn about using the `sub_info` middleware, which allows us to display
additional lines of text under the prompt.  We use this feature to give the user
a short hint about what the current command will do using the `whatis` program.

```crystal
fancy.sub_info.add do |ctx, yielder|
  lines = yielder.call(ctx) # First run the next part of the middleware chain

  if command = get_command(ctx) # Grab the command
    help_line = `whatis #{command} 2> /dev/null`.lines.first?
    lines << help_line if help_line # Display it if we got something
  end

  lines # Return the lines so far
end
```

When you're writing `sub_info` middlewares, make sure that each line fits in a
single line in the terminal. `Fancyline::Context#columns` can tell you how much
space you have. If your middleware wants to display more, just append more
lines.

Possible improvement: Create a `sub_info` middleware which shows the current
time or the weather.

[Complete source](https://github.com/Papierkorb/fancyline/tree/master/samples/tutorial/step4.cr)

### Step 5: Tab Auto-completion

Finally the moment you've been probably waiting for: Adding the most useful
feature a REPL can offer: Auto-completion!  For this we add autocompletion of
paths.

Also look at the
[sample source](https://github.com/Papierkorb/fancyline/tree/master/samples/tutorial/step5.cr#L10)
for this, it offers some more explanation comments.

```crystal
fancy.autocomplete.add do |ctx, range, word, yielder|
  completions = yielder.call(ctx, range, word)

  # The `word` may not suffice for us here.  It'd be fine however for command
  # name completion.

  # Find the range of the current path name near the cursor.
  prev_char = ctx.editor.line[ctx.editor.cursor - 1]?
  if !word.empty? || { '/', '.' }.includes?(prev_char)
    # Then we try to find where it begins and ends
    arg_begin = ctx.editor.line.rindex(' ', ctx.editor.cursor - 1) || 0
    arg_end = ctx.editor.line.index(' ', arg_begin + 1) || ctx.editor.line.size
    range = (arg_begin + 1)...arg_end

    # And using that range we just built, we can find the path the user entered
    path = ctx.editor.line[range].strip
  end

  # Find suggestions and append them to the completions array.
  Dir["#{path}*"].each do |suggestion|
    base = File.basename(suggestion)
    suggestion += '/' if Dir.exists? suggestion
    completions << Fancyline::Completion.new(range, suggestion, base)
  end

  completions
end
```

Now how does this work?  We're now using the third middleware Fancyline offers:
`autocomplete`.  It is used whenever the user hits `TAB` to acquire completion
suggestions.  This is also the first time we're offering the user a new
interaction flow: Multiple TAB hits cycle through the list of suggestions.  You
can build custom flows yourself by creating a **Widget**.  See below for more
on that.

Possible improvement: Add a second `autocomplete` middleware for command
completion.

[Complete source](https://github.com/Papierkorb/fancyline/tree/master/samples/tutorial/step5.cr)

### Step 6: Wrapping things up

Let's wrap this up and add the last things we expect from a shell:
1. Persistant history
2. Not printing a stacktrace on Ctrl-C

For this we modify our trusty while-loop:

```crystal
HISTFILE = "#{Dir.current}/history.log"

if File.exists? HISTFILE # Does it exist?
  puts "  Reading history from #{HISTFILE}"
  File.open(HISTFILE, "r") do |io| # Open a handle
    fancy.history.load io # And load it
  end
end

begin # Get rid of stacktrace on ^C
  while input = fancy.readline("$ ")
    system(input)
  end
rescue err : Fancyline::Interrupt
  puts "Bye."
end

File.open(HISTFILE, "w") do |io| # So open it writable
  fancy.history.save io # And save.  That's it.
end
```

Now we're done!  We built a shell (Or a front-end for a shell) which already
offers lots of functionality expected from a modern shell, all in about 100
lines of code.  There's more Fancyline allows you to do, but this should give
you a pretty good insight in how things are supposed to work.  Happy hacking!

[Complete source](https://github.com/Papierkorb/fancyline/tree/master/samples/tutorial/step6.cr)

## Middlewares

Fancyline uses [cute](https://github.com/Papierkorb/cute) middlewares to allow
you augmenting default behaviour.  If you're familiar with `Ruby Rack` or
`Kemal.cr` you know already the gist of them.

If you're not: Middlewares are basically daisy-chained method calls, which allow
you to change their calling order or add your own calls into the chain.

### `display`

This middleware lets you change how the editor shows the line from the user on
the screen.  This is mostly useful to add syntax-highlighting, showing while the
user is typing.

Have a look at [input_highlighting.cr](https://github.com/Papierkorb/fancyline/tree/master/samples/input_highlighting.cr).

### `autocomplete`

This middleware allows you to add auto-completion to your shell.  The middleware
is called by `Fancyline::Widget::Completion` to present the user with the list
of suggestion to choose from.

See [autocompletion.cr](https://github.com/Papierkorb/fancyline/tree/master/samples/autocompletion.cr).

### `sub_info`

Displays additional lines of text *below* the prompt.  Used by many widgets to
show a small interface.

See [sub_info.cr](https://github.com/Papierkorb/fancyline/tree/master/samples/sub_info.cr).

## Key Bindings

These are the default key bindings.  You can add your own in
`Fancyline#actions`. See also [key_binding.cr](https://github.com/Papierkorb/fancyline/tree/master/samples/key_binding.cr).

|     Key     | Action                                      |
| ----------- | ------------------------------------------- |
| `Ctrl-C`    | Raises `Fancyline::Interrupt`               |
| `Return`    | Accepts the input                           |
| `Ctrl-O`    | Same as `Return`                            |
| `Backspace` | Removes the character left of the cursor    |
| `Delete`    | Removes the character under the cursor      |
| `Left`      | Moves the cursor left                       |
| `Right`     | Moves the cursor right                      |
| `Home`      | Moves the cursor to the beginning           |
| `End`       | Moves the cursor after the last character   |
| `Ctrl-D`    | If buffer is empty, rejects the input       |
| `Ctrl-U`    | Clears the line buffer                      |
| `Ctrl-L`    | Clears the screen                           |
| `Up`        | Activates the **History** widget            |
| `Ctrl-R`    | Activates the **HistorySearch** widget      |

## Widgets

Fancyline uses "Widgets" to augment the behaviour of a running prompt
temporarily.  At any time, there may be up to one widget active.  If one is
active, all user input is first sent to it.  The widget may then choose an
action to take, like acting upon it or continuing default operation.

Some fundamental features you expect to work from a prompt are implemented as
widget.  If you want to create your own, have a look at `Fancyline::Widget` and
[widget.cr](https://github.com/Papierkorb/fancyline/tree/master/samples/widget.cr).

### Completion

Implements TAB-autocompletion using the `autocomplete` middleware.  The original
word can always be recovered by tabbing "outside" the list of suggestions.

|     Key     | Action                         |
| ----------- | ------------------------------ |
| Activate    | Hit `Tab` while in the prompt  |
| `Tab`       | View the next suggestion       |
| `Shift-Tab` | View the previous suggestion   |
| Bold letter | Select the marked suggestion   |
| Any other   | Deactivates the widget         |

If no suggestions were found, the widget stops itself right away.  The user does
not get any visual feedback of this.  If exactly one suggestion was found, it
is applied, and the user can choose between the suggestion and the original
input using `Tab`.

### History

Implements a history, which can be navigated using the Up and Down buttons.
The original input line is retained and can be accessed by going beyond the most
recent history entry.

|    Key    | Action                                    |
| --------- | ----------------------------------------- |
| Activate  | Hit `Up` while in the prompt              |
| `Up`      | Show previous history entry               |
| `Down`    | Show the next (more recent) history entry |
| Any other | Deactivates the widget                    |

### HistorySearch

Implements a history search, which lets you find a specific history entry.
The original input line is retained and can be accessed by going beyond the most
recent match.

|    Key    | Action                             |
| --------- | ---------------------------------- |
| Activate  | Hit `Ctrl-R` while in the prompt   |
| `Up`      | Show previous match                |
| `Down`    | Show the next (more recent) match  |
| `Ctrl-C`  | Cancels and restores original line |
| Any other | Deactivates the widget             |

Shows a sub-info line in the format of `Search X/Y: NEEDLE`, where
* **X** shows the current position in the search matches (Up/Down)
* **Y** shows total count of matches
* **NEEDLE** shows the current search query

If **X** is showing `0`, you're seeing the original line input.

If **NEEDLE** contains only lower-case input, the search is case-insensitive.
If it also contains upper-case input, the search is case-sensitive.

## To Do

* Long input lines, longer than the terminal can display, will break

## Contributing

1. Fork it ( https://github.com/Papierkorb/fancyline/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

## License

This library is licensed under the Mozilla Public License 2.0 ("MPL-2").

For a copy of the full license text see the included `LICENSE` file.

For a legally non-binding explanation visit:
[tl;drLegal](https://tldrlegal.com/license/mozilla-public-license-2.0-%28mpl-2%29)

## Still looking down here?

Thanks for reading, now do something cool and enjoy your day!
